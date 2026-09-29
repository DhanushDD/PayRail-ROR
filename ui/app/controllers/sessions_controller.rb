class SessionsController < ApplicationController
  def new
    redirect_to dashboard_path if logged_in?
    demo_emails = ["demo@payrail.io", "alice@payrail.io", "bob@payrail.io", "billing@novacoffee.com"]
    users = User.where(email: demo_emails)
    @demo_users = demo_emails.map { |email| users.find { |u| u.email == email } }.compact
  end


  def create
    if params[:demo_user_id].present?
      user = User.find_by(id: params[:demo_user_id])
      if user
        session[:user_id] = user.id
        flash[:notice] = "Welcome back, #{user.name}! (Logged in via Recruiter Quick Access)"
        return redirect_to dashboard_path
      end
    end

    identifier = params[:email_or_tag].to_s.strip.downcase
    clean_tag = identifier.delete_prefix("$")

    user = User.where("LOWER(email) = :id OR LOWER(payrail_tag) = :tag", id: identifier, tag: "$#{clean_tag}").first

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      flash[:notice] = "Welcome to PayRail, #{user.name}!"
      redirect_to dashboard_path
    else
      flash.now[:alert] = "Invalid email, PayRail tag, or password."
      @demo_users = User.where(email: ["demo@payrail.io", "alice@payrail.io", "bob@payrail.io", "billing@novacoffee.com"]).limit(4)
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    flash[:notice] = "You have signed out of PayRail."
    redirect_to login_path
  end
end
