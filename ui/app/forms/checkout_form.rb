# frozen_string_literal: true

# CheckoutForm Object (Demonstrating Q72 - Form Objects)
#
# Key Architectural Features:
# 1. ActiveModel Integration: Mixes in `ActiveModel::Model` and `ActiveModel::Attributes`
#    giving plain Ruby classes validations, form helpers, and attribute casting.
# 2. Input Boundary Validation: Validates incoming request parameters prior to persistence.
# 3. Clean Models: Shields ActiveRecord models from parameter parsing and complex conditional validations.
class CheckoutForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :sender_wallet_id, :integer
  attribute :recipient, :string
  attribute :amount, :decimal
  attribute :description, :string
  attribute :category, :string, default: "transfer"

  validates :sender_wallet_id, presence: true
  validates :recipient, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :category, inclusion: { in: %w[transfer dining shopping services bills other] }

  validate :validate_sender_wallet_exists
  validate :validate_recipient_exists

  def amount_cents
    return 0 unless amount
    (amount * 100).to_i
  end

  def sender_wallet
    @sender_wallet ||= Wallet.find_by(id: sender_wallet_id)
  end

  def recipient_wallet
    @recipient_wallet ||= find_recipient_wallet
  end

  private

  def validate_sender_wallet_exists
    errors.add(:sender_wallet_id, "is not a valid active wallet") unless sender_wallet&.active?
  end

  def validate_recipient_exists
    errors.add(:recipient, "could not be found or has no active wallet") unless recipient_wallet&.active?
  end

  def find_recipient_wallet
    clean_tag = recipient.to_s.strip
    clean_tag = "$#{clean_tag}" unless clean_tag.start_with?("$")
    target_user = User.find_by("LOWER(payrail_tag) = LOWER(?) OR LOWER(email) = LOWER(?)", clean_tag, clean_tag)
    target_user&.primary_wallet
  end
end
