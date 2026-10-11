class LedgerEntry < ApplicationRecord
  belongs_to :payment
  belongs_to :wallet

  validates :entry_type, inclusion: { in: %w[debit credit] }
  validates :amount_cents, numericality: { greater_than: 0 }
  validates :balance_after_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :description, presence: true

  def formatted_amount
    prefix = entry_type == "credit" ? "+" : "-"
    format("%s$%.2f", prefix, amount_cents / 100.0)
  end

  def formatted_balance_after
    format("$%.2f", balance_after_cents / 100.0)
  end
end
