module Api
  module V1
    class AuthController < ApplicationController
      before_action :authenticate_api_user!, only: [:me, :logout]

      # POST /api/v1/auth/sign_up (or /api/v1/auth/register)
      def register
        user = User.new(register_params)

        if user.save
          # Enqueue asynchronous welcome email via Sidekiq / ActiveJob
          WelcomeEmailJob.perform_later(user.id)

          token = JwtService.encode(user_id: user.id)

          render json: {
            message: "Account successfully registered",
            token: token,
            user: serialize_user(user)
          }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_content
        end
      end
      alias_method :sign_up, :register

      # POST /api/v1/auth/login
      def login
        user = User.find_by_identifier(params[:email]).first

        if user&.authenticate(params[:password])
          # Enqueue asynchronous login notification & sign-in tracking job
          LoginNotificationJob.perform_later(user.id, request.remote_ip)

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

      # DELETE /api/v1/auth/logout
      def logout
        render json: {
          message: "Successfully logged out",
          user_id: current_user.id
        }, status: :ok
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
        wallet = user.wallet
        {
          id: user.id,
          name: user.name,
          email: user.email,
          payrail_tag: user.payrail_tag,
          role: user.role,
          avatar_color: user.avatar_color,
          api_key: user.api_key,
          sign_in_count: user.sign_in_count,
          last_sign_in_at: user.last_sign_in_at,
          wallet: wallet ? {
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
