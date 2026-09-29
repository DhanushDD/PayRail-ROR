class LedgerController < ApplicationController
  before_action :authenticate_user!

  def index
    @wallet = current_user.primary_wallet
    @filter_type = params[:entry_type]

    entries = @wallet.ledger_entries.includes(transfer: [:sender_wallet, :recipient_wallet])

    if @filter_type.present? && %w[debit credit].include?(@filter_type)
      entries = entries.where(entry_type: @filter_type)
    end

    @ledger_entries = entries.order(created_at: :desc).limit(100)

    # Calculate ledger reconciliation metrics
    @total_debits_cents = @wallet.ledger_entries.where(entry_type: "debit").sum(:amount_cents)
    @total_credits_cents = @wallet.ledger_entries.where(entry_type: "credit").sum(:amount_cents)
    @reconciled_balance_cents = @total_credits_cents - @total_debits_cents
    @is_reconciled = (@reconciled_balance_cents == @wallet.balance_cents)
  end
end
