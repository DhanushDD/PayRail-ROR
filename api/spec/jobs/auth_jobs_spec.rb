require "rails_helper"

RSpec.describe "Background Jobs (Sidekiq & ActiveJob)", type: :job do
  let!(:user) do
    User.create!(
      name: "Job User",
      email: "job@payrail.io",
      payrail_tag: "$jobuser",
      password: "password123"
    )
  end

  describe WelcomeEmailJob do
    it "enqueues on the mailers queue" do
      expect {
        WelcomeEmailJob.perform_later(user.id)
      }.to have_enqueued_job(WelcomeEmailJob).with(user.id).on_queue("mailers")
    end

    it "sends a welcome email when performed" do
      expect {
        WelcomeEmailJob.perform_now(user.id)
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to include(user.email)
      expect(mail.subject).to include("Welcome to PayRail")
    end
  end

  describe LoginNotificationJob do
    it "records sign-in metrics and sends security alert email" do
      expect {
        LoginNotificationJob.perform_now(user.id, "192.168.1.10")
      }.to change { user.reload.sign_in_count }.by(1)
       .and change { ActionMailer::Base.deliveries.count }.by(1)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to include(user.email)
      expect(mail.subject).to include("New Sign-In Detected")
    end
  end

  describe SessionCleanupJob do
    it "audits inactive accounts for cron schedule" do
      user.update_columns(last_sign_in_at: 100.days.ago)
      count = SessionCleanupJob.perform_now
      expect(count).to eq(1)
    end
  end
end
