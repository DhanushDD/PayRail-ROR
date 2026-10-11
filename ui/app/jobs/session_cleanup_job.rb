class SessionCleanupJob < ApplicationJob
  queue_as :maintenance

  def perform
    inactive_threshold = 90.days.ago
    stale_users_count = User.where("last_sign_in_at < ?", inactive_threshold).count
    Rails.logger.info "[SessionCleanupJob] Audited #{stale_users_count} inactive user accounts."
    stale_users_count
  end
end
