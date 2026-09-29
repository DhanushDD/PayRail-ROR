module Api
  module V1
    class TransfersController < ApplicationController
      before_action :authenticate_api_user!
      around_action :handle_idempotency, only: [:create]

      # GET /api/v1/transfers
      def index
        wallet_ids = current_user.wallets.pluck(:id)
        transfers = Transfer.where("sender_wallet_id IN (:ids) OR recipient_wallet_id IN (:ids)", ids: wallet_ids)
                            .order(created_at: :desc)

        if params[:category].present?
          transfers = transfers.where(category: params[:category])
        end

        if params[:status].present?
          transfers = transfers.where(status: params[:status])
        end

        limit = [params[:limit].to_i, 50].max.clamp(1, 100)
        transfers = transfers.limit(limit)

        render json: {
          count: transfers.size,
          transfers: transfers.map { |t| serialize_transfer(t, wallet_ids) }
        }
      end

      # GET /api/v1/transfers/:id
      def show
        wallet_ids = current_user.wallets.pluck(:id)
        transfer = Transfer.where("sender_wallet_id IN (:ids) OR recipient_wallet_id IN (:ids)", ids: wallet_ids)
                           .find_by!(reference_id: params[:id])

        render json: {
          transfer: serialize_transfer(transfer, wallet_ids),
          ledger_audit: transfer.ledger_entries.map do |entry|
            {
              id: entry.id,
              wallet_id: entry.wallet_id,
              wallet_number: entry.wallet.wallet_number,
              entry_type: entry.entry_type,
              amount_cents: entry.amount_cents,
              formatted_amount: entry.formatted_amount,
              balance_after_cents: entry.balance_after_cents,
              formatted_balance_after: entry.formatted_balance_after,
              description: entry.description,
              timestamp: entry.created_at.iso8601
            }
          end
        }
      end

      # GET /api/v1/transfers/lookup_recipient?query=alex
      def lookup_recipient
        query = params[:query].to_s.strip.downcase
        tag_query = query.delete_prefix("$")

        recipient = User.where("LOWER(email) = :q OR LOWER(payrail_tag) = :tag", q: query, tag: "$#{tag_query}")
                        .where.not(id: current_user.id)
                        .first

        if recipient
          render json: {
            found: true,
            user: {
              id: recipient.id,
              name: recipient.name,
              payrail_tag: recipient.payrail_tag,
              avatar_color: recipient.avatar_color,
              kyc_verified: recipient.kyc_verified
            }
          }
        else
          render json: { found: false, message: "No active PayRail user found with that email or $tag." }, status: :not_found
        end
      end

      # POST /api/v1/transfers
      def create
        sender_wallet = current_user.wallets.find_by(id: params[:sender_wallet_id]) || current_user.primary_wallet
        unless sender_wallet
          return render json: { error: "Sender wallet not found" }, status: :bad_request
        end

        recipient_input = params[:recipient].to_s.strip.downcase
        tag_clean = recipient_input.delete_prefix("$")

        recipient_user = User.where("LOWER(email) = :q OR LOWER(payrail_tag) = :tag", q: recipient_input, tag: "$#{tag_clean}").first
        unless recipient_user
          return render json: { error: "Recipient not found", message: "Could not find user with tag or email '#{params[:recipient]}'" }, status: :not_found
        end

        recipient_wallet = recipient_user.primary_wallet
        unless recipient_wallet
          return render json: { error: "Recipient has no active wallet" }, status: :bad_request
        end

        # Calculate cents from amount (e.g. 50.00 -> 5000)
        amount_cents = if params[:amount_cents].present?
                         params[:amount_cents].to_i
                       elsif params[:amount].present?
                         (params[:amount].to_f * 100).round
                       else
                         0
                       end

        result = Transfers::ExecuteService.call(
          sender_wallet: sender_wallet,
          recipient_wallet: recipient_wallet,
          amount_cents: amount_cents,
          fee_cents: 0, # zero fee standard P2P
          description: params[:description],
          category: params[:category] || "transfer",
          idempotency_key: request.headers["Idempotency-Key"] || params[:idempotency_key],
          metadata: { client_ip: request.remote_ip, user_agent: request.user_agent }
        )

        if result.success?
          render json: {
            message: "Transfer completed successfully",
            transfer: serialize_transfer(result.transfer, [sender_wallet.id])
          }, status: :created
        else
          render json: {
            error: "Payment Failed",
            code: result.error_code,
            message: result.error_message
          }, status: :unprocessable_entity
        end
      end

      private

      def serialize_transfer(transfer, user_wallet_ids)
        is_sender = user_wallet_ids.include?(transfer.sender_wallet_id)
        is_recipient = user_wallet_ids.include?(transfer.recipient_wallet_id)
        direction = is_sender ? "debit" : "credit"

        {
          reference_id: transfer.reference_id,
          amount_cents: transfer.amount_cents,
          formatted_amount: transfer.formatted_amount,
          fee_cents: transfer.fee_cents,
          currency: transfer.currency,
          direction: direction,
          transfer_type: transfer.transfer_type,
          status: transfer.status,
          category: transfer.category,
          description: transfer.description,
          sender: transfer.sender_user ? {
            name: transfer.sender_user.name,
            payrail_tag: transfer.sender_user.payrail_tag,
            avatar_color: transfer.sender_user.avatar_color
          } : { name: "External Bank / Card Rail", payrail_tag: "RAIL" },
          recipient: transfer.recipient_user ? {
            name: transfer.recipient_user.name,
            payrail_tag: transfer.recipient_user.payrail_tag,
            avatar_color: transfer.recipient_user.avatar_color
          } : nil,
          created_at: transfer.created_at.iso8601
        }
      end
    end
  end
end
