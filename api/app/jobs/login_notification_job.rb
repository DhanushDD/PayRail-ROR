class LoginNotificationJob < ApplicationJob
  queue_as :default

  def perform(user_id, ip_address = "127.0.0.1")
    user = User.find_by(id: user_id)
    return unless user

    user.record_sign_in!
    UserMailer.login_alert_email(user, ip_address).deliver_now
    Rails.logger.info "[LoginNotificationJob] Processed login notification for #{user.email} from #{ip_address}"
  end
end
