class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
    @jwt_token = JwtService.encode(user_id: @user.id)
  end
end
