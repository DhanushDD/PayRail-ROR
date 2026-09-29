module Api
  module V1
    class AuthController < ApplicationController
      before_action :authenticate_api_user!, only: [:me]

      # POST /api/v1/auth/register
      def register
        user = User.new(register_params)

        if user.save
          # Create default USD primary wallet
          wallet = user.wallets.create!(
            currency: "USD",
            balance_cents: 100000 # Give new accounts $1,000.00 initial funding for demo testing
          )

          # Create initial welcome ledger entry
          transfer = Transfer.create!(
            recipient_wallet: wallet,
            amount_cents: 100000,
            fee_cents: 0,
            currency: "USD",
            transfer_type: "deposit",
            status: "completed",
            category: "deposit",
            description: "PayRail Welcome Bonus Credit"
          )
          LedgerEntry.create!(
            transfer: transfer,
            wallet: wallet,
            entry_type: "credit",
            amount_cents: 100000,
            balance_after_cents: 100000,
            description: "Initial Demo Account Credit"
          )

          # Issue default virtual card
          user.virtual_cards.create!(
            wallet: wallet,
            cardholder_name: user.name.upcase,
            brand: "Visa",
            tier: "Black Metal"
          )

          token = JwtService.encode(user_id: user.id)

          render json: {
            message: "Account successfully registered",
            token: token,
            user: serialize_user(user)
          }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/auth/login
      def login
        login_identifier = params[:email].to_s.strip.downcase
        user = User.find_by("LOWER(email) = :id OR LOWER(payrail_tag) = :id", id: login_identifier)

        if user&.authenticate(params[:password])
          token = JwtService.encode(user_id: user.id)
          render json: {
            message: "Authentication successful",
            token: token,
            user: serialize_user(user)
          }, status: :ok
        else
          render json: { error: "Invalid credentials", message: "Check your email/tag and password." }, status: :unauthorized
        end
      end

      # GET /api/v1/auth/me
      def me
        render json: { user: serialize_user(current_user) }, status: :ok
      end

      private

      def register_params
        params.require(:user).permit(:name, :email, :payrail_tag, :password, :password_confirmation, :phone_number)
      end

      def serialize_user(user)
        wallet = user.primary_wallet
        {
          id: user.id,
          name: user.name,
          email: user.email,
          payrail_tag: user.payrail_tag,
          role: user.role,
          avatar_color: user.avatar_color,
          api_key: user.api_key,
          primary_wallet: wallet ? {
            id: wallet.id,
            wallet_number: wallet.wallet_number,
            currency: wallet.currency,
            balance_cents: wallet.balance_cents,
            formatted_balance: wallet.formatted_balance
          } : nil
        }
      end
    end
  end
end
