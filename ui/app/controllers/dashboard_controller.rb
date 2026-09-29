class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @wallet = current_user.primary_wallet
    @virtual_card = current_user.virtual_cards.first
    @other_users = User.where.not(id: current_user.id).limit(6)

    wallet_ids = current_user.wallets.pluck(:id)
    @transfers = Transfer.where("sender_wallet_id IN (:ids) OR recipient_wallet_id IN (:ids)", ids: wallet_ids)
                         .includes(:sender_wallet, :recipient_wallet)
                         .order(created_at: :desc)
                         .limit(10)

    # Calculate real-time inflow / outflow
    completed_tx = Transfer.where("sender_wallet_id IN (:ids) OR recipient_wallet_id IN (:ids)", ids: wallet_ids)
                           .where(status: "completed")
    @inflow_cents = completed_tx.where(recipient_wallet_id: wallet_ids).sum(:amount_cents)
    @outflow_cents = completed_tx.where(sender_wallet_id: wallet_ids).sum(:amount_cents)

    @recent_ledger_entries = @wallet.ledger_entries.includes(:transfer).order(created_at: :desc).limit(5)
  end
end
