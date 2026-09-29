class Wallet < ApplicationRecord
  belongs_to :user
  has_many :outgoing_transfers, class_name: "Transfer", foreign_key: :sender_wallet_id, dependent: :nullify
  has_many :incoming_transfers, class_name: "Transfer", foreign_key: :recipient_wallet_id, dependent: :nullify
  has_many :ledger_entries, dependent: :destroy
  has_many :virtual_cards, dependent: :destroy
  has_many :payment_links, dependent: :destroy

  validates :wallet_number, presence: true, uniqueness: true
  validates :currency, presence: true, inclusion: { in: %w[USD EUR GBP CAD AUD] }
  validates :balance_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: %w[active frozen closed] }

  before_validation :generate_wallet_number, on: :create

  def active?
    status == "active"
  end

  def formatted_balance
    symbol = case currency
             when "USD" then "$"
             when "EUR" then "€"
             when "GBP" then "£"
             else "$"
             end
    format("#{symbol}%.2f", balance_cents / 100.0)
  end

  def all_transfers
    Transfer.where("sender_wallet_id = :id OR recipient_wallet_id = :id", id: id)
            .order(created_at: :desc)
  end

  private

  def generate_wallet_number
    self.wallet_number ||= "WAL-#{SecureRandom.hex(4).upcase}-#{SecureRandom.hex(2).upcase}"
  end
end
