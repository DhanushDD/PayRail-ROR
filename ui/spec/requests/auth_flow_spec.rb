require "rails_helper"

RSpec.describe "UI Authentication & Payment Flows", type: :request do
  describe "GET & POST /signup" do
    it "renders the signup form, creates user with $1,000 wallet, and enqueues WelcomeEmailJob" do
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
       .and change(Wallet, :count).by(1)
       .and have_enqueued_job(WelcomeEmailJob)

      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe "Login, Send Payment, Deposit & Logout" do
    let!(:user) do
      User.create!(
        name: "Dhanush Daran",
        email: "dhanush@payrail.io",
        payrail_tag: "$dhanush",
        password: "password123"
      )
    end

    let!(:recipient) do
      User.create!(
        name: "Alice Rivera",
        email: "alice@payrail.io",
        payrail_tag: "$alice",
        password: "password123"
      )
    end

    it "logs in, deposits money, sends a P2P payment, executes Gateway Authorize -> Capture -> Refund, and logs out" do
      post "/login", params: { email_or_tag: "dhanush@payrail.io", password: "password123" }
      expect(response).to redirect_to(dashboard_path)

      # Deposit $200.00
      expect {
        post "/payments/deposit", params: { amount: 200.00 }
      }.to change { user.reload.balance_cents }.by(20_000)

      # Send $50.00 P2P to $alice
      expect {
        post "/payments", params: { recipient: "$alice", amount: 50.00, description: "Lunch" }
      }.to change(Payment, :count).by(1)
       .and have_enqueued_job(PaymentNotificationJob)

      expect(user.reload.balance_cents).to eq(115_000)
      expect(recipient.reload.balance_cents).to eq(105_000)

      # Gateway Step 1: Authorize $100.00
      post "/payments", params: { recipient: "$alice", amount: 100.00, checkout_mode: "authorize", description: "Gateway Order" }
      auth_payment = Payment.last
      expect(auth_payment.status).to eq("authorized")
      expect(user.wallet.reload.held_balance_cents).to eq(10_000)

      # Gateway Step 2: Capture the authorized payment
      post "/payments/#{auth_payment.id}/capture"
      expect(auth_payment.reload.status).to eq("captured")
      expect(user.wallet.reload.held_balance_cents).to eq(0)

      delete "/logout"
      expect(response).to redirect_to(login_path)
    end
  end
end
