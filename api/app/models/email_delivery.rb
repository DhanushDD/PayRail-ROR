# frozen_string_literal: true

# EmailDelivery Model (Demonstrating Q149 - Large Email System Design)
#
# Key Features:
# 1. State tracking: persists delivery intent prior to dispatch.
# 2. Idempotency Key: backed by unique database index to guarantee at-most-once sending upon retries.
# 3. Provider Reference: records provider message ID for webhook status convergence (delivered, bounced).
class EmailDelivery < ApplicationRecord
  belongs_to :user, optional: true

  validates :recipient_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :subject, presence: true
  validates :idempotency_key, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[pending sending sent delivered failed bounced] }

  scope :pending, -> { where(status: "pending") }
  scope :sent, -> { where(status: %w[sent delivered]) }

  def mark_sent!(provider_id)
    update!(status: "sent", provider_message_id: provider_id)
  end

  def mark_failed!
    update!(status: "failed")
  end
end
