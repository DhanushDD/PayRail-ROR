module Api
  module V1
    class PaymentsController < ApplicationController
      before_action :authenticate_api_user!

      # GET /api/v1/payments
      def index
        payments = current_user.recent_payments(25)
        render json: {
          wallet: {
            wallet_number: current_user.wallet.wallet_number,
            balance_cents: current_user.balance_cents,
            formatted_balance: current_user.formatted_balance
          },
          payments: payments.map { |p| serialize_payment(p) }
        }, status: :ok
      end

      # POST /api/v1/payments
      def create
        recipient = User.find_by_identifier(params[:recipient]).first
        unless recipient
          return render json: { error: "Recipient not found" }, status: :not_found
        end

        amount_cents = (params[:amount].to_f * 100).round
        payment = Payment.transfer!(
          sender: current_user,
          recipient: recipient,
          amount_cents: amount_cents,
          description: params[:description]
        )

        render json: {
          message: "Payment completed successfully",
          payment: serialize_payment(payment),
          wallet_balance: current_user.reload.formatted_balance
        }, status: :created
      rescue ArgumentError, StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # POST /api/v1/payments/deposit
      def deposit
        amount_cents = (params[:amount].to_f * 100).round
        payment = current_user.wallet.deposit!(
          amount_cents,
          description: params[:description].presence || "Added Money via Bank Rail"
        )

        render json: {
          message: "Funds added to wallet",
          payment: serialize_payment(payment),
          wallet_balance: current_user.reload.formatted_balance
        }, status: :created
      rescue ArgumentError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def serialize_payment(payment)
        {
          id: payment.id,
          reference_id: payment.reference_id,
          payment_type: payment.payment_type,
          amount_cents: payment.amount_cents,
          formatted_amount: payment.formatted_amount,
          currency: payment.currency,
          status: payment.status,
          description: payment.description,
          sender: payment.sender ? { name: payment.sender.name, payrail_tag: payment.sender.payrail_tag } : nil,
          recipient: { name: payment.recipient.name, payrail_tag: payment.recipient.payrail_tag },
          created_at: payment.created_at
        }
      end
    end
  end
end
