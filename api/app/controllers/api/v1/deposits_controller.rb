module Api
  module V1
    class DepositsController < ApplicationController
      before_action :authenticate_api_user!

      # POST /api/v1/deposits
      def create
        wallet = current_user.wallets.find_by(id: params[:wallet_id]) || current_user.primary_wallet
        unless wallet
          return render json: { error: "Wallet not found" }, status: :bad_request
        end

        amount_cents = if params[:amount_cents].present?
                         params[:amount_cents].to_i
                       elsif params[:amount].present?
                         (params[:amount].to_f * 100).round
                       else
                         0
                       end

        payment_method = params[:payment_method] || "instant_ach"

        result = Deposits::ProcessService.call(
          wallet: wallet,
          amount_cents: amount_cents,
          payment_method: payment_method,
          description: params[:description]
        )

        if result.success?
          render json: {
            message: "Funds successfully deposited into wallet",
            wallet: {
              id: wallet.id,
              balance_cents: wallet.reload.balance_cents,
              formatted_balance: wallet.formatted_balance
            },
            transfer_reference: result.transfer.reference_id
          }, status: :created
        else
          render json: { error: "Deposit failed", message: result.error_message }, status: :unprocessable_entity
        end
      end
    end
  end
end
