require "rails_helper"

RSpec.describe "API V1 Payments (Wallet Balance, P2P Transfer & Deposit)", type: :request do
  let!(:sender) do
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

  let(:headers) { { "Authorization" => "Bearer #{JwtService.encode(user_id: sender.id)}" } }

  describe "POST /api/v1/payments" do
    it "transfers funds between wallets atomically and enqueues PaymentNotificationJob" do
      expect(sender.balance_cents).to eq(100_000) # $1,000.00 default
      expect(recipient.balance_cents).to eq(100_000)

      expect {
        post "/api/v1/payments",
             params: { recipient: "$alice", amount: 150.00, description: "Project Milestone" },
             headers: headers
      }.to change(Payment, :count).by(1)
       .and have_enqueued_job(PaymentNotificationJob)

      expect(response).to have_http_status(:created)
      expect(sender.reload.balance_cents).to eq(85_000)
      expect(recipient.reload.balance_cents).to eq(115_000)
    end

    it "rejects transfer when balance is insufficient" do
      post "/api/v1/payments",
           params: { recipient: "$alice", amount: 5000.00 },
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]).to include("Insufficient wallet balance")
    end
  end

  describe "POST /api/v1/payments/deposit" do
    it "adds funds to user wallet and records a deposit payment" do
      expect {
        post "/api/v1/payments/deposit",
             params: { amount: 250.00, description: "Bank Top Up" },
             headers: headers
      }.to change { sender.reload.balance_cents }.by(25_000)

      expect(response).to have_http_status(:created)
    end
  end

  describe "GET /api/v1/payments" do
    it "returns wallet balance and recent payment history" do
      Payment.transfer!(sender: sender, recipient: recipient, amount_cents: 5_000, description: "Coffee")

      get "/api/v1/payments", headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["wallet"]["balance_cents"]).to eq(95_000)
      expect(json["payments"].first["formatted_amount"]).to eq("$50.00")
    end
  end
end
