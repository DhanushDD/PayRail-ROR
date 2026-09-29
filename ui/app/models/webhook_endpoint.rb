class WebhookEndpoint < ApplicationRecord
  belongs_to :user
  has_many :webhook_deliveries, dependent: :destroy

  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :secret, presence: true

  before_validation :generate_secret, on: :create

  private

  def generate_secret
    self.secret ||= "whsec_" + SecureRandom.hex(16)
  end
end
