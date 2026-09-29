class CardsController < ApplicationController
  before_action :authenticate_user!

  def index
    @cards = current_user.virtual_cards.order(created_at: :desc)
    @wallet = current_user.primary_wallet
  end

  def create
    wallet = current_user.primary_wallet
    card = current_user.virtual_cards.create!(
      wallet: wallet,
      cardholder_name: (params[:cardholder_name].presence || current_user.name).upcase,
      brand: params[:brand] || "Visa",
      tier: params[:tier] || "Black Metal",
      monthly_limit_cents: (params[:monthly_limit].to_f * 100).to_i.positive? ? (params[:monthly_limit].to_f * 100).to_i : 500000
    )

    flash[:notice] = "New #{card.tier} #{card.brand} virtual card issued successfully!"
    redirect_to cards_path
  end

  def toggle_freeze
    card = current_user.virtual_cards.find(params[:id])
    new_status = card.active? ? "frozen" : "active"
    card.update!(status: new_status)

    flash[:notice] = "Card #{card.masked_number} has been #{new_status == 'active' ? 'unfrozen' : 'frozen'}."
    redirect_back fallback_location: cards_path
  end
end
