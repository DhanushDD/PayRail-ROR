class Wallet < ApplicationRecord
  belongs_to :user

  validates :wallet_number, presence: true, uniqueness: true
  validates :currency, presence: true
  validates :balance_cents, numericality: { greater_than_or_equal_to: 0 }

  before_validation :assign_wallet_number, on: :create

  def formatted_balance
    format("$%.2f", balance_cents / 100.0)
  end

  def deposit!(amount_cents, description: "Added Funds to Wallet")
    raise ArgumentError, "Amount must be positive" if amount_cents <= 0

    transaction do
      lock!
      update!(balance_cents: self.balance_cents + amount_cents)
      Payment.create!(
        sender: nil,
        recipient: user,
        amount_cents: amount_cents,
        currency: currency,
        payment_type: "deposit",
        status: "completed",
        description: description
      )
    end
  end

  private

  def assign_wallet_number
    self.wallet_number ||= "PR-" + SecureRandom.hex(4).upcase
  end
end
