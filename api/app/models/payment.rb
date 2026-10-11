class Payment < ApplicationRecord
  belongs_to :sender, class_name: "User", optional: true
  belongs_to :recipient, class_name: "User"

  validates :reference_id, presence: true, uniqueness: true
  validates :amount_cents, numericality: { greater_than: 0 }
  validates :payment_type, inclusion: { in: %w[transfer deposit] }
  validates :status, inclusion: { in: %w[pending completed failed] }

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

  # Execute P2P payment transfer between two users safely inside a DB transaction
  def self.transfer!(sender:, recipient:, amount_cents:, description: "P2P Payment")
    raise ArgumentError, "Recipient is required" unless recipient
    raise ArgumentError, "Cannot send money to yourself" if sender.id == recipient.id
    raise ArgumentError, "Amount must be greater than $0.00" if amount_cents.to_i <= 0

    payment = nil

    transaction do
      sender_wallet = sender.wallet.lock!
      recipient_wallet = recipient.wallet.lock!

      if sender_wallet.balance_cents < amount_cents
        raise StandardError, "Insufficient wallet balance (#{sender_wallet.formatted_balance} available)"
      end

      sender_wallet.update!(balance_cents: sender_wallet.balance_cents - amount_cents)
      recipient_wallet.update!(balance_cents: recipient_wallet.balance_cents + amount_cents)

      payment = create!(
        sender: sender,
        recipient: recipient,
        amount_cents: amount_cents,
        currency: sender_wallet.currency,
        payment_type: "transfer",
        status: "completed",
        description: description.presence || "Payment to #{recipient.payrail_tag}"
      )
    end

    # Enqueue Sidekiq background job for payment receipt notification
    PaymentNotificationJob.perform_later(payment.id)
    payment
  end

  private

  def assign_reference_id
    self.reference_id ||= "PAY-" + SecureRandom.hex(5).upcase
  end
end
