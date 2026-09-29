module Api
  module V1
    class CardsController < ApplicationController
      before_action :authenticate_api_user!

      # GET /api/v1/cards
      def index
        cards = current_user.virtual_cards.order(created_at: :desc)
        render json: {
          cards: cards.map { |c| serialize_card(c) }
        }
      end

      # POST /api/v1/cards
      def create
        wallet = current_user.primary_wallet
        card = current_user.virtual_cards.create!(
          wallet: wallet,
          cardholder_name: (params[:cardholder_name].presence || current_user.name).upcase,
          brand: params[:brand] || "Visa",
          tier: params[:tier] || "Black Metal",
          monthly_limit_cents: (params[:monthly_limit_dollars].to_f * 100).to_i.positive? ? (params[:monthly_limit_dollars].to_f * 100).to_i : 500000
        )

        render json: { message: "Virtual card issued", card: serialize_card(card) }, status: :created
      end

      # PATCH /api/v1/cards/:id/toggle_freeze
      def toggle_freeze
        card = current_user.virtual_cards.find(params[:id])
        new_status = card.active? ? "frozen" : "active"
        card.update!(status: new_status)

        render json: {
          message: "Card #{new_status == 'active' ? 'unfrozen' : 'frozen'} successfully",
          card: serialize_card(card)
        }
      end

      private

      def serialize_card(card)
        {
          id: card.id,
          masked_number: card.masked_number,
          card_number_full: card.card_number_full,
          cardholder_name: card.cardholder_name,
          expiry: card.formatted_expiry,
          cvv: card.cvv,
          brand: card.brand,
          tier: card.tier,
          status: card.status,
          monthly_limit_cents: card.monthly_limit_cents,
          formatted_monthly_limit: card.formatted_monthly_limit,
          spent_this_month_cents: card.spent_this_month_cents,
          created_at: card.created_at.iso8601
        }
      end
    end
  end
end
