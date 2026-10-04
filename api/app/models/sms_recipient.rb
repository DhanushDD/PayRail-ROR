# frozen_string_literal: true

# SmsRecipient Model (Demonstrating Q150 - SMS Campaign Recipient Batching)
class SmsRecipient < ApplicationRecord
  belongs_to :sms_campaign

  validates :phone_number, presence: true
  validates :status, inclusion: { in: %w[pending sent failed] }

  scope :pending, -> { where(status: "pending") }
  scope :sent, -> { where(status: "sent") }

  def mark_sent!(provider_id)
    update!(status: "sent", provider_message_id: provider_id)
  end

  def mark_failed!
    update!(status: "failed")
  end
end
