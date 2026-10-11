class SessionsController < ApplicationController
  def new
    redirect_to dashboard_path if logged_in?
    demo_emails = ["demo@payrail.io", "alice@payrail.io", "bob@payrail.io"]
    users = User.where(email: demo_emails)
    @demo_users = demo_emails.map { |email| users.find { |u| u.email == email } }.compact
  end

  def create
    if params[:demo_user_id].present?
      user = User.find_by(id: params[:demo_user_id])
      if user
        session[:user_id] = user.id
        LoginNotificationJob.perform_later(user.id, request.remote_ip)
        flash[:notice] = "Welcome back, #{user.name}! (Logged in via Quick Access)"
        return redirect_to dashboard_path
      end
    end

    user = User.find_by_identifier(params[:email_or_tag]).first

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      LoginNotificationJob.perform_later(user.id, request.remote_ip)
      flash[:notice] = "Welcome to PayRail, #{user.name}!"
      redirect_to dashboard_path
    else
      flash.now[:alert] = "Invalid email, PayRail tag, or password."
      @demo_users = User.where(email: ["demo@payrail.io", "alice@payrail.io", "bob@payrail.io"]).limit(3)
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    session[:user_id] = nil
    flash[:notice] = "You have signed out of PayRail."
    redirect_to login_path
  end
end
