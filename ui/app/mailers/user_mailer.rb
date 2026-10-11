class UserMailer < ApplicationMailer
  default from: ENV.fetch("SMTP_FROM_EMAIL", "notifications@payrail.io")

  def welcome_email(user)
    @user = user
    mail(
      to: @user.email,
      subject: "Welcome to PayRail, #{@user.name}!"
    ) do |format|
      format.text { render plain: "Welcome to PayRail, #{@user.name} (#{@user.payrail_tag})! Your wallet is funded with #{user.formatted_balance}." }
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

  def payment_receipt_email(payment)
    @payment = payment
    @recipient = payment.recipient
    @sender = payment.sender
    mail(
      to: @recipient.email,
      subject: "PayRail Payment Received: #{@payment.formatted_amount} (#{@payment.reference_id})"
    ) do |format|
      format.text do
        sender_name = @sender ? "#{@sender.name} (#{@sender.payrail_tag})" : "Bank Deposit"
        render plain: "Hi #{@recipient.name}, you received #{@payment.formatted_amount} from #{sender_name}. Reference: #{@payment.reference_id}."
      end
    end
  end
end
