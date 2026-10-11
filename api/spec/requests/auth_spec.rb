require "rails_helper"

RSpec.describe "API V1 Authentication (Sign Up / Login / Logout)", type: :request do
  describe "POST /api/v1/auth/sign_up" do
    let(:valid_params) do
      {
        user: {
          name: "Dhanush Daran",
          email: "dhanush@payrail.io",
          payrail_tag: "dhanush",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    it "registers a new user, returns a JWT token, and enqueues WelcomeEmailJob" do
      expect {
        post "/api/v1/auth/sign_up", params: valid_params
      }.to change(User, :count).by(1)
       .and have_enqueued_job(WelcomeEmailJob)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["token"]).to be_present
      expect(json["user"]["email"]).to eq("dhanush@payrail.io")
      expect(json["user"]["payrail_tag"]).to eq("$dhanush")
    end

    it "returns 422 unprocessable_entity on invalid params" do
      post "/api/v1/auth/sign_up", params: { user: { name: "", email: "bad" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) do
      User.create!(
        name: "Alice Rivera",
        email: "alice@payrail.io",
        payrail_tag: "$alice",
        password: "password123"
      )
    end

    it "authenticates with valid email and enqueues LoginNotificationJob" do
      expect {
        post "/api/v1/auth/login", params: { email: "alice@payrail.io", password: "password123" }
      }.to have_enqueued_job(LoginNotificationJob)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["token"]).to be_present
      expect(json["user"]["email"]).to eq("alice@payrail.io")
    end

    it "authenticates with payrail_tag" do
      post "/api/v1/auth/login", params: { email: "$alice", password: "password123" }
      expect(response).to have_http_status(:ok)
    end

    it "rejects invalid credentials with 401 unauthorized" do
      post "/api/v1/auth/login", params: { email: "alice@payrail.io", password: "wrong" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/auth/logout & GET /api/v1/auth/me" do
    let!(:user) do
      User.create!(
        name: "Bob Vance",
        email: "bob@payrail.io",
        payrail_tag: "$bob",
        password: "password123"
      )
    end
    let(:token) { JwtService.encode(user_id: user.id) }

    it "returns current user profile with valid Bearer token" do
      get "/api/v1/auth/me", headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["user"]["email"]).to eq("bob@payrail.io")
    end

    it "logs out an authenticated user" do
      delete "/api/v1/auth/logout", headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("Successfully logged out")
    end

    it "returns 401 unauthorized without token" do
      delete "/api/v1/auth/logout"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
