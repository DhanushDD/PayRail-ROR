class WebhookDelivery < ApplicationRecord
  belongs_to :webhook_endpoint

  validates :event_type, presence: true
  validates :payload, presence: true

  def parsed_payload
    JSON.parse(payload) rescue payload
  end
end
