class DeveloperController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
    @api_key = @user.api_key
    @jwt_token = JwtService.encode(user_id: @user.id)
    @webhooks = @user.webhook_endpoints
    @recent_deliveries = WebhookDelivery.where(webhook_endpoint: @webhooks).order(created_at: :desc).limit(10)
    @api_base_url = ENV.fetch("PAYRAIL_API_URL", "http://localhost:3000/api/v1")
  end

  def test_api
    endpoint = params[:endpoint]
    client = PayrailApiClient.new(token: JwtService.encode(user_id: current_user.id))

    response = case endpoint
               when "wallets"
                 client.wallets
               when "transfers"
                 client.transfers(limit: 5)
               when "analytics"
                 client.analytics
               else
                 { error: "Unknown test endpoint" }
               end

    render json: response
  end
end
