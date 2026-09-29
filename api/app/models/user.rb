class User < ApplicationRecord
  has_secure_password

  has_many :wallets, dependent: :destroy
  has_many :virtual_cards, dependent: :destroy
  has_many :payment_links, dependent: :destroy
  has_many :webhook_endpoints, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :payrail_tag, presence: true, uniqueness: { case_sensitive: false }

  before_validation :normalize_attributes
  before_create :generate_api_credentials

  def primary_wallet
    wallets.find_by(currency: "USD") || wallets.first
  end

  def total_balance_cents
    wallets.sum(:balance_cents)
  end

  def formatted_total_balance
    format("$%.2f", total_balance_cents / 100.0)
  end

  private

  def normalize_attributes
    self.email = email.to_s.strip.downcase
    if payrail_tag.present?
      clean_tag = payrail_tag.to_s.strip.delete_prefix("$").downcase
      self.payrail_tag = "$#{clean_tag}"
    end
  end

  def generate_api_credentials
    self.api_key ||= "pr_live_" + SecureRandom.hex(16)
    self.avatar_color ||= ["#3B82F6", "#10B981", "#8B5CF6", "#F59E0B", "#EC4899", "#06B6D4"].sample
  end
end
