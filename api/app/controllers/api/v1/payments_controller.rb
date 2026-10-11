module Api
  module V1
    class PaymentsController < ApplicationController
      before_action :authenticate_api_user!

      # GET /api/v1/payments
      def index
        payments = current_user.recent_payments(25)
        ledger = current_user.recent_ledger_entries(25)
        render json: {
          wallet: {
            wallet_number: current_user.wallet.wallet_number,
            balance_cents: current_user.balance_cents,
            formatted_balance: current_user.formatted_balance
          },
          payments: payments.map { |p| serialize_payment(p) },
          ledger_entries: ledger.map { |entry| serialize_ledger_entry(entry) }
        }, status: :ok
      end

      # POST /api/v1/payments
      def create
        recipient = User.find_by_identifier(params[:recipient]).first
        unless recipient
          return render json: { error: "Recipient not found" }, status: :not_found
        end

        idempotency_key = request.headers["Idempotency-Key"].presence || params[:idempotency_key].presence
        amount_cents = (params[:amount].to_f * 100).round

        payment = Payment.transfer!(
          sender: current_user,
          recipient: recipient,
          amount_cents: amount_cents,
          description: params[:description],
          idempotency_key: idempotency_key
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
        idempotency_key = request.headers["Idempotency-Key"].presence || params[:idempotency_key].presence
        amount_cents = (params[:amount].to_f * 100).round

        payment = current_user.wallet.deposit!(
          amount_cents,
          description: params[:description].presence || "Added Money via Bank Rail",
          idempotency_key: idempotency_key
        )

        render json: {
          message: "Funds added to wallet",
          payment: serialize_payment(payment),
          wallet_balance: current_user.reload.formatted_balance
        }, status: :created
      rescue ArgumentError, StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # POST /api/v1/payments/:id/refund
      def refund
        payment = Payment.find_by(id: params[:id]) || Payment.find_by(reference_id: params[:id])
        unless payment
          return render json: { error: "Payment not found" }, status: :not_found
        end

        refund_payment = payment.refund!(actor: current_user)

        render json: {
          message: "Payment refunded successfully",
          refund_payment: serialize_payment(refund_payment),
          wallet_balance: current_user.reload.formatted_balance
        }, status: :ok
      rescue StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def serialize_payment(payment)
        {
          id: payment.id,
          reference_id: payment.reference_id,
          idempotency_key: payment.idempotency_key,
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

      def serialize_ledger_entry(entry)
        {
          id: entry.id,
          payment_reference: entry.payment.reference_id,
          entry_type: entry.entry_type,
          amount_cents: entry.amount_cents,
          formatted_amount: entry.formatted_amount,
          balance_after_cents: entry.balance_after_cents,
          formatted_balance_after: entry.formatted_balance_after,
          description: entry.description,
          created_at: entry.created_at
        }
      end
    end
  end
end
