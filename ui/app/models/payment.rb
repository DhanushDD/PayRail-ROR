class Payment < ApplicationRecord
  belongs_to :sender, class_name: "User", optional: true
  belongs_to :recipient, class_name: "User"
  belongs_to :parent_payment, class_name: "Payment", optional: true
  has_many :ledger_entries, dependent: :destroy

  validates :reference_id, presence: true, uniqueness: true
  validates :idempotency_key, uniqueness: true, allow_nil: true
  validates :gateway_transaction_id, uniqueness: true, allow_nil: true
  validates :amount_cents, numericality: { greater_than: 0 }
  validates :payment_type, inclusion: { in: %w[transfer deposit refund gateway_charge] }
  validates :status, inclusion: { in: %w[pending authorized captured completed voided refunded failed] }

  before_validation :assign_reference_id, on: :create

  scope :for_user, ->(user_id) {
    where("sender_id = :uid OR recipient_id = :uid", uid: user_id)
  }

  def formatted_amount
    format("$%.2f", amount_cents / 100.0)
  end

  def formatted_fee
    format("$%.2f", fee_cents / 100.0)
  end

  def formatted_net_amount
    format("$%.2f", net_amount_cents / 100.0)
  end

  def credit_for?(user)
    recipient_id == user.id
  end

  def capturable_by?(user)
    status == "authorized" && (recipient_id == user.id || sender_id == user.id)
  end

  def voidable_by?(user)
    status == "authorized" && (recipient_id == user.id || sender_id == user.id)
  end

  def refundable_by?(user)
    %w[transfer gateway_charge].include?(payment_type) &&
      %w[completed captured].include?(status) &&
      recipient_id == user.id
  end

  # =========================================================================
  # GATEWAY WORKFLOW STEP 1: AUTHORIZE (Places Hold on Customer Funds)
  # =========================================================================
  def self.authorize!(sender:, recipient:, amount_cents:, description: "Gateway Authorization", payment_method_token: "tok_visa_4242", idempotency_key: nil)
    raise ArgumentError, "Recipient is required" unless recipient
    raise ArgumentError, "Cannot authorize payment to yourself" if sender.id == recipient.id
    raise ArgumentError, "Amount must be greater than $0.00" if amount_cents.to_i <= 0

    if idempotency_key.present?
      existing = find_by(idempotency_key: idempotency_key)
      return existing if existing
    end

    fee = PaymentGatewayService.calculate_fee_cents(amount_cents)
    net = [amount_cents - fee, 0].max

    gw_response = PaymentGatewayService.authorize_charge(
      amount_cents: amount_cents,
      payment_method_token: payment_method_token
    )

    payment = nil
    transaction do
      sender_wallet = sender.wallet.lock!
      if sender_wallet.balance_cents < amount_cents
        raise StandardError, "Insufficient wallet balance for authorization (#{sender_wallet.formatted_balance} available)"
      end

      sender_wallet.update!(
        balance_cents: sender_wallet.balance_cents - amount_cents,
        held_balance_cents: sender_wallet.held_balance_cents + amount_cents
      )

      payment = create!(
        sender: sender,
        recipient: recipient,
        amount_cents: amount_cents,
        fee_cents: fee,
        net_amount_cents: net,
        currency: sender_wallet.currency,
        payment_type: "gateway_charge",
        status: "authorized",
        description: description.presence || "Authorized Gateway Charge",
        idempotency_key: idempotency_key,
        gateway_provider: gw_response[:gateway_provider],
        gateway_transaction_id: gw_response[:gateway_transaction_id],
        authorization_code: gw_response[:authorization_code],
        payment_method_token: gw_response[:payment_method_token],
        authorized_at: gw_response[:authorized_at]
      )
    end

    payment
  end

  # =========================================================================
  # GATEWAY WORKFLOW STEP 2A: CAPTURE / SETTLE (Settles Hold & Credits Merchant)
  # =========================================================================
  def capture!
    raise StandardError, "Only authorized payments can be captured (current status: #{status})" unless status == "authorized"

    self.class.transaction do
      lock!
      raise StandardError, "Payment already captured" if status == "captured"

      wallets = Wallet.where(user_id: [sender_id, recipient_id]).order(:id).lock
      sender_wallet = wallets.find { |w| w.user_id == sender_id }
      recipient_wallet = wallets.find { |w| w.user_id == recipient_id }

      new_held = [sender_wallet.held_balance_cents - amount_cents, 0].max
      new_recipient_balance = recipient_wallet.balance_cents + net_amount_cents

      sender_wallet.update!(held_balance_cents: new_held)
      recipient_wallet.update!(balance_cents: new_recipient_balance)

      update!(
        status: "captured",
        captured_at: Time.current
      )

      LedgerEntry.create!(
        payment: self,
        wallet: sender_wallet,
        entry_type: "debit",
        amount_cents: amount_cents,
        balance_after_cents: sender_wallet.balance_cents,
        description: "Gateway Capture (#{authorization_code}) to #{recipient.payrail_tag}"
      )

      LedgerEntry.create!(
        payment: self,
        wallet: recipient_wallet,
        entry_type: "credit",
        amount_cents: net_amount_cents,
        balance_after_cents: new_recipient_balance,
        description: "Gateway Settlement (#{reference_id}, Fee: #{formatted_fee})"
      )
    end

    PaymentNotificationJob.perform_later(id)
    self
  end

  # =========================================================================
  # GATEWAY WORKFLOW STEP 2B: VOID / CANCEL (Releases Authorization Hold)
  # =========================================================================
  def void!
    raise StandardError, "Only authorized payments can be voided (current status: #{status})" unless status == "authorized"

    self.class.transaction do
      lock!
      sender_wallet = sender.wallet.lock!

      new_held = [sender_wallet.held_balance_cents - amount_cents, 0].max
      new_available = sender_wallet.balance_cents + amount_cents

      sender_wallet.update!(
        balance_cents: new_available,
        held_balance_cents: new_held
      )

      update!(
        status: "voided",
        voided_at: Time.current
      )
    end

    self
  end

  # =========================================================================
  # INSTANT P2P TRANSFER (Direct Authorize + Capture in 1 Step)
  # =========================================================================
  def self.transfer!(sender:, recipient:, amount_cents:, description: "P2P Payment", idempotency_key: nil)
    raise ArgumentError, "Recipient is required" unless recipient
    raise ArgumentError, "Cannot send money to yourself" if sender.id == recipient.id
    raise ArgumentError, "Amount must be greater than $0.00" if amount_cents.to_i <= 0

    if idempotency_key.present?
      existing = find_by(idempotency_key: idempotency_key)
      return existing if existing
    end

    payment = nil

    transaction do
      wallets = Wallet.where(user_id: [sender.id, recipient.id]).order(:id).lock
      sender_wallet = wallets.find { |w| w.user_id == sender.id }
      recipient_wallet = wallets.find { |w| w.user_id == recipient.id }

      if sender_wallet.balance_cents < amount_cents
        raise StandardError, "Insufficient wallet balance (#{sender_wallet.formatted_balance} available)"
      end

      new_sender_balance = sender_wallet.balance_cents - amount_cents
      new_recipient_balance = recipient_wallet.balance_cents + amount_cents

      sender_wallet.update!(balance_cents: new_sender_balance)
      recipient_wallet.update!(balance_cents: new_recipient_balance)

      note = description.presence || "Payment to #{recipient.payrail_tag}"

      payment = create!(
        sender: sender,
        recipient: recipient,
        amount_cents: amount_cents,
        fee_cents: 0,
        net_amount_cents: amount_cents,
        currency: sender_wallet.currency,
        payment_type: "transfer",
        status: "completed",
        description: note,
        idempotency_key: idempotency_key,
        gateway_transaction_id: "gw_p2p_#{SecureRandom.hex(6)}",
        captured_at: Time.current
      )

      LedgerEntry.create!(
        payment: payment,
        wallet: sender_wallet,
        entry_type: "debit",
        amount_cents: amount_cents,
        balance_after_cents: new_sender_balance,
        description: "Sent to #{recipient.name} (#{recipient.payrail_tag})"
      )

      LedgerEntry.create!(
        payment: payment,
        wallet: recipient_wallet,
        entry_type: "credit",
        amount_cents: amount_cents,
        balance_after_cents: new_recipient_balance,
        description: "Received from #{sender.name} (#{sender.payrail_tag})"
      )
    end

    PaymentNotificationJob.perform_later(payment.id)
    payment
  end

  # =========================================================================
  # GATEWAY WORKFLOW STEP 3: REFUND / REVERSAL
  # =========================================================================
  def refund!(actor: nil)
    unless %w[transfer gateway_charge].include?(payment_type) && %w[completed captured].include?(status)
      raise StandardError, "Only completed or captured payments can be refunded"
    end
    raise StandardError, "Only the recipient can issue a refund" if actor && actor.id != recipient_id

    refund_payment = nil
    refund_debit_cents = net_amount_cents.positive? ? net_amount_cents : amount_cents

    self.class.transaction do
      lock!
      raise StandardError, "Payment has already been refunded" if status == "refunded"

      wallets = Wallet.where(user_id: [sender_id, recipient_id]).order(:id).lock
      original_sender_wallet = wallets.find { |w| w.user_id == sender_id }
      original_recipient_wallet = wallets.find { |w| w.user_id == recipient_id }

      if original_recipient_wallet.balance_cents < refund_debit_cents
        raise StandardError, "Insufficient balance to refund this payment"
      end

      new_recipient_balance = original_recipient_wallet.balance_cents - refund_debit_cents
      new_sender_balance = original_sender_wallet.balance_cents + amount_cents

      original_recipient_wallet.update!(balance_cents: new_recipient_balance)
      original_sender_wallet.update!(balance_cents: new_sender_balance)

      update!(status: "refunded", refunded_at: Time.current)

      refund_payment = self.class.create!(
        sender: recipient,
        recipient: sender,
        amount_cents: amount_cents,
        fee_cents: 0,
        net_amount_cents: amount_cents,
        currency: currency,
        payment_type: "refund",
        status: "completed",
        description: "Refund for #{reference_id}",
        parent_payment_id: id,
        gateway_transaction_id: "gw_rfnd_#{SecureRandom.hex(6)}",
        captured_at: Time.current
      )

      LedgerEntry.create!(
        payment: refund_payment,
        wallet: original_recipient_wallet,
        entry_type: "debit",
        amount_cents: refund_debit_cents,
        balance_after_cents: new_recipient_balance,
        description: "Refunded #{reference_id} to #{sender.payrail_tag}"
      )

      LedgerEntry.create!(
        payment: refund_payment,
        wallet: original_sender_wallet,
        entry_type: "credit",
        amount_cents: amount_cents,
        balance_after_cents: new_sender_balance,
        description: "Refund received for #{reference_id} from #{recipient.payrail_tag}"
      )
    end

    PaymentNotificationJob.perform_later(refund_payment.id)
    refund_payment
  end

  private

  def assign_reference_id
    self.reference_id ||= "PAY-" + SecureRandom.hex(5).upcase
  end
end
