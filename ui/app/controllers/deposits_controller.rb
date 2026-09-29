class DepositsController < ApplicationController
  before_action :authenticate_user!

  def create
    wallet = current_user.primary_wallet
    amount_cents = (params[:amount].to_f * 100).round

    result = Deposits::ProcessService.call(
      wallet: wallet,
      amount_cents: amount_cents,
      payment_method: params[:payment_method] || "instant_ach",
      description: "Direct Deposit via #{params[:payment_method]&.titleize || 'ACH Bank Rail'}"
    )

    if result.success?
      flash[:notice] = "Successfully deposited #{result.transfer.formatted_amount} to your PayRail wallet!"
    else
      flash[:alert] = "Deposit failed: #{result.error_message}"
    end

    redirect_to dashboard_path
  end
end
