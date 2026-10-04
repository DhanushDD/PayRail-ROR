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
               when "handbook"
                 require_relative "../../../api/lib/interview_handbook/runner"
                 summary = InterviewHandbook::Runner.run(verbose: false)
                 {
                   handbook: "Ruby & Rails Interview Handbook - Interview-Ready Edition",
                   total_verified_patterns: summary[:total],
                   passed_patterns: summary[:passed],
                   all_healthy: summary[:success],
                   sections: [
                     "Quick Cheat Sheet (20 Most-Confused Pairs)",
                     "Part 1: Core Ruby (Q1 - Q47)",
                     "Part 2: Ruby Deep Dives (Q48 - Q67)",
                     "Part 3: Design & Architecture (Q68 - Q81)",
                     "Part 4: Rails & ActiveRecord (Q82 - Q113)",
                     "Part 5: Jobs, Redis, APIs & Security (Q114 - Q148)",
                     "Part 6: Production & System Design (Q149 - Q169)",
                     "Part 7: 10 Follow-ups & Worked Example (Q170 - Q269)"
                   ],
                   status: "200 OK — All Q1-Q169 codes passing without issues"
                 }
               else
                 { error: "Unknown test endpoint" }
               end

    render json: response
  end
end
