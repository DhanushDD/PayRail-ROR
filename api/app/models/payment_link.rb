class PaymentLink < ApplicationRecord
  belongs_to :user
  belongs_to :wallet

  validates :link_token, presence: true, uniqueness: true
  validates :title, presence: true
  validates :amount_cents, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[active claimed expired cancelled] }

  before_validation :generate_link_token, on: :create

  def active?
    status == "active"
  end

  def formatted_amount
    format("$%.2f", amount_cents / 100.0)
  end

  private

  def generate_link_token
    self.link_token ||= "pay_" + SecureRandom.hex(8)
  end
end
