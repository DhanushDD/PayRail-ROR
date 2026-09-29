class LedgerEntry < ApplicationRecord
  belongs_to :transfer
  belongs_to :wallet

  validates :entry_type, inclusion: { in: %w[debit credit] }
  validates :amount_cents, numericality: { greater_than: 0 }
  validates :balance_after_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :description, presence: true

  scope :debits, -> { where(entry_type: "debit") }
  scope :credits, -> { where(entry_type: "credit") }
  scope :recent, -> { order(created_at: :desc) }

  def debit?
    entry_type == "debit"
  end

  def credit?
    entry_type == "credit"
  end

  def formatted_amount
    symbol = debit? ? "-" : "+"
    format("#{symbol}$%.2f", amount_cents / 100.0)
  end

  def formatted_balance_after
    format("$%.2f", balance_after_cents / 100.0)
  end
end
