class RegistrationsController < ApplicationController
  def new
    redirect_to dashboard_path if logged_in?
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      # Trigger asynchronous welcome email via Sidekiq / ActiveJob
      WelcomeEmailJob.perform_later(@user.id)

      session[:user_id] = @user.id
      flash[:notice] = "Welcome to PayRail! Your account has been created."
      redirect_to dashboard_path
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :payrail_tag, :password, :password_confirmation, :phone_number)
  end
end
