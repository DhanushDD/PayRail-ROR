require "rails_helper"

RSpec.describe "UI Authentication Flows (Sign Up / Login / Logout)", type: :request do
  describe "GET & POST /signup" do
    it "renders the signup form and creates a new user session" do
      get "/signup"
      expect(response).to have_http_status(:ok)

      expect {
        post "/signup", params: {
          user: {
            name: "UI User",
            email: "uiuser@payrail.io",
            payrail_tag: "uiuser",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      }.to change(User, :count).by(1)
       .and have_enqueued_job(WelcomeEmailJob)

      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe "GET /login, POST /login, DELETE /logout" do
    let!(:user) do
      User.create!(
        name: "Dhanush Daran",
        email: "dhanush@payrail.io",
        payrail_tag: "$dhanush",
        password: "password123"
      )
    end

    it "logs in with valid credentials and logs out cleanly" do
      get "/login"
      expect(response).to have_http_status(:ok)

      expect {
        post "/login", params: { email_or_tag: "dhanush@payrail.io", password: "password123" }
      }.to have_enqueued_job(LoginNotificationJob)

      expect(response).to redirect_to(dashboard_path)

      delete "/logout"
      expect(response).to redirect_to(login_path)
    end
  end
end
