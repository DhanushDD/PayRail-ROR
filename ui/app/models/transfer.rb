class Transfer < ApplicationRecord
  belongs_to :sender_wallet, class_name: "Wallet", optional: true
  belongs_to :recipient_wallet, class_name: "Wallet"
  has_many :ledger_entries, dependent: :destroy

  validates :reference_id, presence: true, uniqueness: true
  validates :amount_cents, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :transfer_type, inclusion: { in: %w[p2p deposit card_purchase payment_link refund withdrawal] }
  validates :status, inclusion: { in: %w[completed pending failed reversed] }

  before_validation :generate_reference_id, on: :create

  scope :completed, -> { where(status: "completed") }
  scope :recent, -> { order(created_at: :desc) }

  def formatted_amount
    format("$%.2f", amount_cents / 100.0)
  end

  def formatted_fee
    format("$%.2f", fee_cents / 100.0)
  end

  def total_deduction_cents
    amount_cents + fee_cents
  end

  def sender_user
    sender_wallet&.user
  end

  def recipient_user
    recipient_wallet&.user
  end

  def direction_for(wallet)
    if wallet.id == sender_wallet_id
      "debit"
    elsif wallet.id == recipient_wallet_id
      "credit"
    else
      "unrelated"
    end
  end

  private

  def generate_reference_id
    self.reference_id ||= "TRX-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
  end
end
