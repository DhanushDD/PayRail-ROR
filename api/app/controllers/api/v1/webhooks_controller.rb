module Api
  module V1
    class WebhooksController < ApplicationController
      # POST /api/v1/webhooks/gateway
      # Verifies HMAC-SHA256 signature, records idempotent WebhookEvent, and enqueues GatewayWebhookJob
      def gateway
        raw_body = request.raw_post
        signature = request.headers["X-PayRail-Signature"]

        unless PaymentGatewayService.verify_webhook_signature!(raw_body, signature)
          return render json: { error: "Invalid webhook signature" }, status: :unauthorized
        end

        payload = JSON.parse(raw_body)
        event_id = payload["event_id"].presence || "evt_#{SecureRandom.hex(6)}"

        # Idempotent webhook deduplication
        existing_event = WebhookEvent.find_by(event_id: event_id)
        if existing_event
          return render json: { message: "Webhook already received", event_id: existing_event.event_id, status: existing_event.status }, status: :ok
        end

        webhook_event = WebhookEvent.create!(
          event_id: event_id,
          event_type: payload["event_type"],
          gateway_transaction_id: payload["gateway_transaction_id"],
          payload: payload,
          status: "pending"
        )

        GatewayWebhookJob.perform_later(webhook_event.id)

        render json: {
          message: "Webhook accepted for asynchronous processing",
          event_id: webhook_event.event_id,
          event_type: webhook_event.event_type
        }, status: :accepted
      rescue JSON::ParserError
        render json: { error: "Invalid JSON payload" }, status: :bad_request
      end
    end
  end
end
