# frozen_string_literal: true

# OutboxEvent Model (Demonstrating Q124 - The Outbox Pattern)
#
# Solves the dual-write problem between database commits and message broker publishing.
# Both the domain change (e.g. creating a payment) and the outbox event row are written
# within the EXACT SAME database transaction:
#   ApplicationRecord.transaction do
#     create_transfer(...)
#     OutboxEvent.create!(...)
#   end
# A separate worker or poller then dispatches pending outbox events and marks them 'published'.
class OutboxEvent < ApplicationRecord
  validates :event_type, presence: true
  validates :aggregate_type, presence: true
  validates :aggregate_id, presence: true
  validates :payload, presence: true
  validates :status, inclusion: { in: %w[pending published failed] }

  scope :pending, -> { where(status: "pending").order(created_at: :asc) }
  scope :published, -> { where(status: "published") }

  # Mark event as successfully published to message broker/event stream
  def mark_published!
    update!(status: "published", published_at: Time.current)
  end

  # Mark event as failed after retry attempts
  def mark_failed!
    update!(status: "failed")
  end
end
