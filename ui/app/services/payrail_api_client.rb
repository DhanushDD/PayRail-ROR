require "net/http"
require "uri"
require "json"

class PayrailApiClient
  DEFAULT_BASE_URL = ENV.fetch("PAYRAIL_API_URL", "http://127.0.0.1:3000/api/v1")

  def initialize(base_url: DEFAULT_BASE_URL, api_key: nil, token: nil)
    @base_url = base_url.chomp("/")
    @api_key = api_key
    @token = token
  end

  def health
    get("/")
  end

  def wallets
    get("/wallets")
  end

  def transfers(params = {})
    get("/transfers", params)
  end

  def create_transfer(params = {}, idempotency_key: nil)
    post("/transfers", params, idempotency_key: idempotency_key)
  end

  def lookup_recipient(query)
    get("/transfers/lookup_recipient", { query: query })
  end

  def deposit(params = {})
    post("/deposits", params)
  end

  def cards
    get("/cards")
  end

  def toggle_card_freeze(card_id)
    patch("/cards/#{card_id}/toggle_freeze")
  end

  def payment_links
    get("/payment_links")
  end

  def analytics
    get("/analytics/overview")
  end

  def webhooks
    get("/webhooks")
  end

  private

  def get(path, params = {})
    uri = URI("#{@base_url}#{path}")
    uri.query = URI.encode_www_form(params) if params.present?

    req = Net::HTTP::Get.new(uri)
    execute(req, uri)
  end

  def post(path, body = {}, idempotency_key: nil)
    uri = URI("#{@base_url}#{path}")
    req = Net::HTTP::Post.new(uri)
    req.body = body.to_json
    req["Content-Type"] = "application/json"
    req["Idempotency-Key"] = idempotency_key if idempotency_key.present?
    execute(req, uri)
  end

  def patch(path, body = {})
    uri = URI("#{@base_url}#{path}")
    req = Net::HTTP::Patch.new(uri)
    req.body = body.to_json
    req["Content-Type"] = "application/json"
    execute(req, uri)
  end

  def execute(req, uri)
    req["Authorization"] = "Bearer #{@token}" if @token.present?
    req["X-API-Key"] = @api_key if @api_key.present?
    req["Accept"] = "application/json"

    res = Net::HTTP.start(uri.hostname, uri.port, read_timeout: 5, open_timeout: 3) do |http|
      http.request(req)
    end

    parsed_data = begin
                    JSON.parse(res.body)
                  rescue StandardError
                    res.body
                  end

    {
      code: res.code.to_i,
      success: res.is_a?(Net::HTTPSuccess),
      data: parsed_data,
      headers: res.to_hash
    }

  rescue StandardError => e
    {
      code: 503,
      success: false,
      error: "API Unreachable",
      message: e.message
    }
  end
end
