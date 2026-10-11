class UserMailer < ApplicationMailer
  default from: ENV.fetch("SMTP_FROM_EMAIL", "notifications@payrail.io")

  def welcome_email(user)
    @user = user
    mail(
      to: @user.email,
      subject: "Welcome to PayRail, #{@user.name}!"
    ) do |format|
      format.text { render plain: "Welcome to PayRail, #{@user.name} (#{@user.payrail_tag})! Your account is active." }
    end
  end

  def login_alert_email(user, ip_address)
    @user = user
    @ip_address = ip_address
    mail(
      to: @user.email,
      subject: "PayRail Security Alert: New Sign-In Detected"
    ) do |format|
      format.text { render plain: "Hi #{@user.name}, a new sign-in was detected on your account from IP: #{@ip_address}." }
    end
  end
end
