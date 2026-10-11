class WelcomeEmailJob < ApplicationJob
  queue_as :mailers

  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    UserMailer.welcome_email(user).deliver_now
    Rails.logger.info "[WelcomeEmailJob] Sent welcome email to #{user.email}"
  end
end
