class GatewayWebhookJob < ApplicationJob
  queue_as :webhooks

  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(webhook_event_id)
    event = WebhookEvent.find_by(id: webhook_event_id)
    return unless event && event.status == "pending"

    payment = Payment.find_by(gateway_transaction_id: event.gateway_transaction_id) ||
              Payment.find_by(reference_id: event.payload["reference_id"])

    case event.event_type
    when "payment.captured"
      payment.capture! if payment && payment.status == "authorized"
    when "payment.voided"
      payment.void! if payment && payment.status == "authorized"
    when "payment.refunded"
      payment.refund! if payment && %w[completed captured].include?(payment.status)
    when "payment.failed"
      if payment && payment.status == "authorized"
        payment.void!
        payment.update!(status: "failed", failure_reason: event.payload["reason"] || "Gateway settlement failed")
      end
    end

    event.update!(status: "processed", processed_at: Time.current)
    Rails.logger.info "[GatewayWebhookJob] Processed gateway event #{event.event_id} (#{event.event_type})"
  rescue StandardError => e
    event&.update(status: "failed", error_message: e.message)
    raise e
  end
end
