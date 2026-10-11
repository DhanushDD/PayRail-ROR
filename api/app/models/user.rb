class User < ApplicationRecord
  has_secure_password

  has_one :wallet, dependent: :destroy
  has_many :sent_payments, class_name: "Payment", foreign_key: :sender_id, dependent: :nullify
  has_many :received_payments, class_name: "Payment", foreign_key: :recipient_id, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :payrail_tag, presence: true, uniqueness: { case_sensitive: false }

  before_validation :normalize_attributes
  before_create :generate_api_credentials
  after_create :create_default_wallet!

  # Optimized query scope for finding user by email or payrail_tag
  scope :find_by_identifier, ->(identifier) {
    clean_id = identifier.to_s.strip.downcase
    clean_tag = clean_id.delete_prefix("$")
    where("LOWER(email) = :id OR LOWER(payrail_tag) = :tag", id: clean_id, tag: "$#{clean_tag}")
  }

  scope :active_customers, -> { where(role: "customer", kyc_verified: true).order(created_at: :desc) }

  def balance_cents
    wallet&.balance_cents || 0
  end

  def formatted_balance
    wallet ? wallet.formatted_balance : "$0.00"
  end

  def recent_payments(limit = 15)
    Payment.for_user(id).includes(:sender, :recipient).order(created_at: :desc).limit(limit)
  end

  def record_sign_in!
    update_columns(
      last_sign_in_at: Time.current,
      sign_in_count: sign_in_count + 1
    )
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

  def create_default_wallet!
    create_wallet!(currency: "USD", balance_cents: 100_000) unless wallet
  end
end
