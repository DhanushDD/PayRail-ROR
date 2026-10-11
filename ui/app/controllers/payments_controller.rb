class PaymentsController < ApplicationController
  before_action :authenticate_user!

  def create
    recipient = User.find_by_identifier(params[:recipient]).first
    unless recipient
      flash[:alert] = "Recipient '#{params[:recipient]}' not found."
      return redirect_to dashboard_path
    end

    amount_cents = (params[:amount].to_f * 100).round

    if params[:checkout_mode] == "authorize"
      payment = Payment.authorize!(
        sender: current_user,
        recipient: recipient,
        amount_cents: amount_cents,
        description: params[:description],
        payment_method_token: params[:payment_method_token].presence || "tok_visa_4242",
        idempotency_key: params[:idempotency_key].presence
      )
      flash[:notice] = "Authorized #{payment.formatted_amount} (#{payment.authorization_code})! Hold placed — click Capture or Void below."
    else
      payment = Payment.transfer!(
        sender: current_user,
        recipient: recipient,
        amount_cents: amount_cents,
        description: params[:description],
        idempotency_key: params[:idempotency_key].presence
      )
      flash[:notice] = "Sent #{payment.formatted_amount} to #{recipient.name} (#{recipient.payrail_tag})! Ref: #{payment.reference_id}"
    end

    redirect_to dashboard_path
  rescue ArgumentError, StandardError => e
    flash[:alert] = e.message
    redirect_to dashboard_path
  end

  def capture
    payment = Payment.find(params[:id])
    payment.capture!
    flash[:notice] = "Captured #{payment.formatted_amount} (Net: #{payment.formatted_net_amount}, Gateway Fee: #{payment.formatted_fee})!"
    redirect_to dashboard_path
  rescue StandardError => e
    flash[:alert] = e.message
    redirect_to dashboard_path
  end

  def void
    payment = Payment.find(params[:id])
    payment.void!
    flash[:notice] = "Voided authorization #{payment.reference_id}. Held funds (#{payment.formatted_amount}) released back to wallet."
    redirect_to dashboard_path
  rescue StandardError => e
    flash[:alert] = e.message
    redirect_to dashboard_path
  end

  def deposit
    amount_cents = (params[:amount].to_f * 100).round
    payment = current_user.wallet.deposit!(
      amount_cents,
      description: params[:description].presence || "Added Money via Linked Bank"
    )

    flash[:notice] = "Added #{payment.formatted_amount} to your PayRail Wallet! Ref: #{payment.reference_id}"
    redirect_to dashboard_path
  rescue ArgumentError, StandardError => e
    flash[:alert] = e.message
    redirect_to dashboard_path
  end

  def refund
    payment = Payment.find(params[:id])
    refund_payment = payment.refund!(actor: current_user)
    flash[:notice] = "Refunded #{refund_payment.formatted_amount} to #{refund_payment.recipient.name} (#{refund_payment.reference_id})."
    redirect_to dashboard_path
  rescue StandardError => e
    flash[:alert] = e.message
    redirect_to dashboard_path
  end
end
