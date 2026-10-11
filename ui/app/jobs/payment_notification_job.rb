class PaymentNotificationJob < ApplicationJob
  queue_as :payments

  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(payment_id)
    payment = Payment.find_by(id: payment_id)
    return unless payment

    UserMailer.payment_receipt_email(payment).deliver_now
    Rails.logger.info "[PaymentNotificationJob] Dispatched receipt for #{payment.reference_id} (#{payment.formatted_amount})"
  end
end

