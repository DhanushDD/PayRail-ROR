module Api
  module V1
    class AnalyticsController < ApplicationController
      before_action :authenticate_api_user!

      # GET /api/v1/analytics/overview
      def overview
        wallet_ids = current_user.wallets.pluck(:id)

        all_tx = Transfer.where("sender_wallet_id IN (:ids) OR recipient_wallet_id IN (:ids)", ids: wallet_ids)
                         .where(status: "completed")

        inflow_cents = all_tx.where(recipient_wallet_id: wallet_ids).sum(:amount_cents)
        outflow_cents = all_tx.where(sender_wallet_id: wallet_ids).sum(:amount_cents)
        total_tx_count = all_tx.count

        # Monthly breakdown
        monthly_sent = all_tx.where(sender_wallet_id: wallet_ids)
                             .where("created_at >= ?", 30.days.ago)
                             .sum(:amount_cents)
        monthly_received = all_tx.where(recipient_wallet_id: wallet_ids)
                                 .where("created_at >= ?", 30.days.ago)
                                 .sum(:amount_cents)

        render json: {
          current_balance: current_user.formatted_total_balance,
          total_inflow: format("$%.2f", inflow_cents / 100.0),
          total_outflow: format("$%.2f", outflow_cents / 100.0),
          net_volume_cents: inflow_cents - outflow_cents,
          total_transactions: total_tx_count,
          last_30_days: {
            sent: format("$%.2f", monthly_sent / 100.0),
            received: format("$%.2f", monthly_received / 100.0),
            velocity_ratio: total_tx_count > 0 ? (monthly_sent.to_f / [inflow_cents, 1].max).round(2) : 0.0
          }
        }
      end
    end
  end
end
