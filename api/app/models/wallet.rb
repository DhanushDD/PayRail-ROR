class Wallet < ApplicationRecord
  belongs_to :user
  has_many :ledger_entries, dependent: :destroy

  validates :wallet_number, presence: true, uniqueness: true
  validates :currency, presence: true
  validates :balance_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :held_balance_cents, numericality: { greater_than_or_equal_to: 0 }

  before_validation :assign_wallet_number, on: :create

  def formatted_balance
    format("$%.2f", balance_cents / 100.0)
  end

  def formatted_held_balance
    format("$%.2f", held_balance_cents / 100.0)
  end

  # Deposit funds into wallet with pessimistic locking and immutable ledger entry
  def deposit!(amount_cents, description: "Added Funds to Wallet", idempotency_key: nil)
    raise ArgumentError, "Amount must be positive" if amount_cents.to_i <= 0

    if idempotency_key.present?
      existing = Payment.find_by(idempotency_key: idempotency_key)
      return existing if existing
    end

    payment = nil
    transaction do
      lock!
      new_balance = balance_cents + amount_cents
      update!(balance_cents: new_balance)

      payment = Payment.create!(
        sender: nil,
        recipient: user,
        amount_cents: amount_cents,
        fee_cents: 0,
        net_amount_cents: amount_cents,
        currency: currency,
        payment_type: "deposit",
        status: "completed",
        description: description,
        idempotency_key: idempotency_key,
        captured_at: Time.current
      )

      ledger_entries.create!(
        payment: payment,
        entry_type: "credit",
        amount_cents: amount_cents,
        balance_after_cents: new_balance,
        description: description
      )
    end
    payment
  end

  private

  def assign_wallet_number
    self.wallet_number ||= "PR-" + SecureRandom.hex(4).upcase
  end
end
