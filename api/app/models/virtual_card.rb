class VirtualCard < ApplicationRecord
  belongs_to :user
  belongs_to :wallet

  validates :card_number_last4, presence: true
  validates :card_number_full, presence: true
  validates :cardholder_name, presence: true
  validates :expiry_month, inclusion: { in: 1..12 }
  validates :expiry_year, numericality: { greater_than_or_equal_to: 2026 }
  validates :cvv, presence: true
  validates :status, inclusion: { in: %w[active frozen terminated] }

  before_validation :generate_card_details, on: :create

  def active?
    status == "active"
  end

  def formatted_expiry
    format("%02d/%02d", expiry_month, expiry_year % 100)
  end

  def masked_card_number
    "•••• •••• •••• #{card_number_last4}"
  end
  alias_method :masked_number, :masked_card_number


  def formatted_full_number
    card_number_full.scan(/.{1,4}/).join(" ")
  end

  def available_limit_cents
    [monthly_limit_cents - spent_this_month_cents, 0].max
  end

  def formatted_monthly_limit
    format("$%.2f", monthly_limit_cents / 100.0)
  end

  private

  def generate_card_details
    if card_number_full.blank?
      # Generates a valid 16-digit test card starting with 4242 (Visa test)
      random_middle = Array.new(8) { rand(0..9) }.join
      random_last = Array.new(4) { rand(0..9) }.join
      self.card_number_full = "4242#{random_middle}#{random_last}"
      self.card_number_last4 = random_last
    end
    self.cvv ||= sprintf("%03d", rand(100..999))
    self.expiry_month ||= rand(1..12)
    self.expiry_year ||= Time.current.year + rand(2..4)
  end
end
