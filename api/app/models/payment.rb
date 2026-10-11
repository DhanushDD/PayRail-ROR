class Payment < ApplicationRecord
  belongs_to :sender, class_name: "User", optional: true
  belongs_to :recipient, class_name: "User"
  belongs_to :parent_payment, class_name: "Payment", optional: true
  has_many :ledger_entries, dependent: :destroy

  validates :reference_id, presence: true, uniqueness: true
  validates :idempotency_key, uniqueness: true, allow_nil: true
  validates :amount_cents, numericality: { greater_than: 0 }
  validates :payment_type, inclusion: { in: %w[transfer deposit refund] }
  validates :status, inclusion: { in: %w[pending completed refunded failed] }

  before_validation :assign_reference_id, on: :create

  scope :for_user, ->(user_id) {
    where("sender_id = :uid OR recipient_id = :uid", uid: user_id)
  }

  def formatted_amount
    format("$%.2f", amount_cents / 100.0)
  end

  def credit_for?(user)
    recipient_id == user.id
  end

  def refundable_by?(user)
    payment_type == "transfer" && status == "completed" && recipient_id == user.id
  end

  # Payment Fundamental 1: Atomic P2P Transfer with Pessimistic Locking, Double-Entry Ledger & Idempotency
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
      # Lock wallets in deterministic ID order to prevent deadlocks
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
        currency: sender_wallet.currency,
        payment_type: "transfer",
        status: "completed",
        description: note,
        idempotency_key: idempotency_key
      )

      # Double-entry bookkeeping: 1 Debit entry + 1 Credit entry
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

    # Enqueue Sidekiq background job for payment receipt notification
    PaymentNotificationJob.perform_later(payment.id)
    payment
  end

  # Payment Fundamental 2: Atomic Payment Refund / Reversal with Double-Entry Ledger
  def refund!(actor: nil)
    raise StandardError, "Only completed transfers can be refunded" unless payment_type == "transfer" && status == "completed"
    raise StandardError, "Only the recipient can issue a refund" if actor && actor.id != recipient_id

    refund_payment = nil

    self.class.transaction do
      lock!
      raise StandardError, "Payment has already been refunded" if status == "refunded"

      wallets = Wallet.where(user_id: [sender_id, recipient_id]).order(:id).lock
      original_sender_wallet = wallets.find { |w| w.user_id == sender_id }
      original_recipient_wallet = wallets.find { |w| w.user_id == recipient_id }

      if original_recipient_wallet.balance_cents < amount_cents
        raise StandardError, "Insufficient balance to refund this payment"
      end

      new_recipient_balance = original_recipient_wallet.balance_cents - amount_cents
      new_sender_balance = original_sender_wallet.balance_cents + amount_cents

      original_recipient_wallet.update!(balance_cents: new_recipient_balance)
      original_sender_wallet.update!(balance_cents: new_sender_balance)

      update!(status: "refunded")

      refund_payment = self.class.create!(
        sender: recipient,
        recipient: sender,
        amount_cents: amount_cents,
        fee_cents: 0,
        currency: currency,
        payment_type: "refund",
        status: "completed",
        description: "Refund for #{reference_id}",
        parent_payment_id: id
      )

      LedgerEntry.create!(
        payment: refund_payment,
        wallet: original_recipient_wallet,
        entry_type: "debit",
        amount_cents: amount_cents,
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
