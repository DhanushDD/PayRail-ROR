module Api
  module V1
    class WalletsController < ApplicationController
      before_action :authenticate_api_user!
      before_action :set_wallet, only: [:show, :ledger]

      # GET /api/v1/wallets
      def index
        wallets = current_user.wallets.order(created_at: :asc)
        render json: {
          total_balance_cents: current_user.total_balance_cents,
          formatted_total_balance: current_user.formatted_total_balance,
          wallets: wallets.map { |w| serialize_wallet(w) }
        }
      end

      # GET /api/v1/wallets/:id
      def show
        render json: { wallet: serialize_wallet(@wallet) }
      end

      # GET /api/v1/wallets/:id/ledger
      def ledger
        entries = @wallet.ledger_entries.includes(:transfer).order(created_at: :desc).limit(params[:limit] || 50)
        render json: {
          wallet_id: @wallet.id,
          wallet_number: @wallet.wallet_number,
          current_balance: @wallet.formatted_balance,
          ledger_entries: entries.map do |entry|
            {
              id: entry.id,
              entry_type: entry.entry_type,
              amount_cents: entry.amount_cents,
              formatted_amount: entry.formatted_amount,
              balance_after_cents: entry.balance_after_cents,
              formatted_balance_after: entry.formatted_balance_after,
              description: entry.description,
              transfer_reference: entry.transfer.reference_id,
              created_at: entry.created_at.iso8601
            }
          end
        }
      end

      private

      def set_wallet
        @wallet = current_user.wallets.find(params[:id])
      end

      def serialize_wallet(wallet)
        {
          id: wallet.id,
          wallet_number: wallet.wallet_number,
          currency: wallet.currency,
          balance_cents: wallet.balance_cents,
          formatted_balance: wallet.formatted_balance,
          status: wallet.status,
          daily_limit_cents: wallet.daily_limit_cents,
          created_at: wallet.created_at.iso8601
        }
      end
    end
  end
end
