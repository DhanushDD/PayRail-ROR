module Api
  module V1
    class WebhooksController < ApplicationController
      before_action :authenticate_api_user!

      # GET /api/v1/webhooks
      def index
        endpoints = current_user.webhook_endpoints
        deliveries = WebhookDelivery.where(webhook_endpoint: endpoints).order(created_at: :desc).limit(30)

        render json: {
          endpoints: endpoints.map { |e| { id: e.id, url: e.url, secret: e.secret, active: e.active } },
          recent_deliveries: deliveries.map do |d|
            {
              id: d.id,
              event_type: d.event_type,
              status: d.status,
              response_code: d.response_code,
              payload: d.parsed_payload,
              delivered_at: d.created_at.iso8601
            }
          end
        }
      end

      # POST /api/v1/webhooks
      def create
        endpoint = current_user.webhook_endpoints.create!(
          url: params[:url]
        )
        render json: { endpoint: { id: endpoint.id, url: endpoint.url, secret: endpoint.secret } }, status: :created
      end
    end
  end
end
