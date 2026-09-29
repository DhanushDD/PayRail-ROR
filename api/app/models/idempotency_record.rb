class IdempotencyRecord < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :request_path, presence: true
  validates :response_code, presence: true
  validates :response_body, presence: true

  def parsed_response_body
    JSON.parse(response_body) rescue response_body
  end
end
