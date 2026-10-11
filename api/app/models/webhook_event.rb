class WebhookEvent < ApplicationRecord
  validates :event_id, presence: true, uniqueness: true
  validates :event_type, presence: true
  validates :status, inclusion: { in: %w[pending processed failed] }
end
