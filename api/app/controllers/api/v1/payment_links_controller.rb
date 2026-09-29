module Api
  module V1
    class PaymentLinksController < ApplicationController
      before_action :authenticate_api_user!, except: [:show, :pay]

      # GET /api/v1/payment_links
      def index
        links = current_user.payment_links.order(created_at: :desc)
        render json: {
          links: links.map { |l| serialize_link(l) }
        }
      end

      # POST /api/v1/payment_links
      def create
        wallet = current_user.primary_wallet
        amount_cents = (params[:amount].to_f * 100).round

        link = current_user.payment_links.create!(
          wallet: wallet,
          title: params[:title].presence || "Payment Request",
          description: params[:description],
          amount_cents: amount_cents,
          currency: wallet.currency
        )

        render json: {
          message: "Payment link created",
          payment_link: serialize_link(link)
        }, status: :created
      end

      # GET /api/v1/payment_links/:token (Public)
      def show
        link = PaymentLink.find_by!(link_token: params[:token])
        render json: {
          payment_link: serialize_link(link)
        }
      end

      # POST /api/v1/payment_links/:token/pay (Public checkout with simulated card or sender)
      def pay
        link = PaymentLink.find_by!(link_token: params[:token])
        if link.status != "active"
          return render json: { error: "Link inactive", message: "This payment link has already been #{link.status}." }, status: :unprocessable_entity
        end

        payer_name = params[:payer_name].presence || "Guest Customer"
        recipient_wallet = link.wallet

        # Execute credit into merchant wallet
        ActiveRecord::Base.transaction do
          recipient_wallet.lock!
          recipient_wallet.increment!(:balance_cents, link.amount_cents)

          transfer = Transfer.create!(
            sender_wallet_id: nil,
            recipient_wallet: recipient_wallet,
            amount_cents: link.amount_cents,
            fee_cents: 0,
            currency: link.currency,
            transfer_type: "payment_link",
            status: "completed",
            category: "shopping",
            description: "Checkout: #{link.title} (Paid by #{payer_name})",
            metadata: { link_token: link.link_token, payer: payer_name }
          )

          LedgerEntry.create!(
            transfer: transfer,
            wallet: recipient_wallet,
            entry_type: "credit",
            amount_cents: link.amount_cents,
            balance_after_cents: recipient_wallet.balance_cents,
            description: "Payment Link Credit: #{link.title}"
          )

          link.update!(status: "claimed", claimed_by_name: payer_name)

          render json: {
            message: "Payment settled successfully",
            reference_id: transfer.reference_id,
            amount: link.formatted_amount
          }
        end
      end

      private

      def serialize_link(link)
        {
          id: link.id,
          token: link.link_token,
          title: link.title,
          description: link.description,
          amount_cents: link.amount_cents,
          formatted_amount: link.formatted_amount,
          currency: link.currency,
          status: link.status,
          merchant_name: link.user.name,
          merchant_tag: link.user.payrail_tag,
          claimed_by_name: link.claimed_by_name,
          checkout_url: "/checkout/#{link.link_token}",
          created_at: link.created_at.iso8601
        }
      end
    end
  end
end
