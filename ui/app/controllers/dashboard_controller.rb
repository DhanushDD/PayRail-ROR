class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
    @wallet = @user.wallet
    @peers = User.where.not(id: @user.id).order(:name)
    @payments = @user.recent_payments(15)
    @jwt_token = JwtService.encode(user_id: @user.id)
  end
end
