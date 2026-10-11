require "rails_helper"

RSpec.describe "API V1 Payments Fundamentals (Transfer, Idempotency, Double-Entry Ledger, Deposit & Refund)", type: :request do
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

  describe "POST /api/v1/payments (P2P Transfer, Double-Entry Ledger & Idempotency)" do
    it "transfers funds atomically, records debit & credit ledger entries, and enqueues PaymentNotificationJob" do
      expect(sender.balance_cents).to eq(100_000) # $1,000.00 default
      expect(recipient.balance_cents).to eq(100_000)

      expect {
        post "/api/v1/payments",
             params: { recipient: "$alice", amount: 150.00, description: "Project Milestone" },
             headers: headers
      }.to change(Payment, :count).by(1)
       .and change(LedgerEntry, :count).by(2)
       .and have_enqueued_job(PaymentNotificationJob)

      expect(response).to have_http_status(:created)
      expect(sender.reload.balance_cents).to eq(85_000)
      expect(recipient.reload.balance_cents).to eq(115_000)
    end

    it "prevents duplicate charges when the same Idempotency-Key header is retried" do
      idem_headers = headers.merge("Idempotency-Key" => "idem_unique_123")

      post "/api/v1/payments",
           params: { recipient: "$alice", amount: 100.00, description: "First Attempt" },
           headers: idem_headers
      expect(response).to have_http_status(:created)

      # Retry identical request with same Idempotency-Key
      expect {
        post "/api/v1/payments",
             params: { recipient: "$alice", amount: 100.00, description: "Retry Attempt" },
             headers: idem_headers
      }.not_to change { sender.reload.balance_cents }
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

  describe "POST /api/v1/payments/:id/refund (Payment Reversal & Refund)" do
    it "allows recipient to refund a completed payment and reverses wallet balances & ledger entries" do
      payment = Payment.transfer!(sender: sender, recipient: recipient, amount_cents: 20_000, description: "Order #101")
      expect(sender.reload.balance_cents).to eq(80_000)
      expect(recipient.reload.balance_cents).to eq(120_000)

      recipient_headers = { "Authorization" => "Bearer #{JwtService.encode(user_id: recipient.id)}" }

      expect {
        post "/api/v1/payments/#{payment.id}/refund", headers: recipient_headers
      }.to change(Payment, :count).by(1)
       .and change(LedgerEntry, :count).by(2)

      expect(response).to have_http_status(:ok)
      expect(payment.reload.status).to eq("refunded")
      expect(sender.reload.balance_cents).to eq(100_000)
      expect(recipient.reload.balance_cents).to eq(100_000)
    end
  end

  describe "POST /api/v1/payments/deposit" do
    it "adds funds to user wallet and records a credit ledger entry" do
      expect {
        post "/api/v1/payments/deposit",
             params: { amount: 250.00, description: "Bank Top Up" },
             headers: headers
      }.to change { sender.reload.balance_cents }.by(25_000)
       .and change(LedgerEntry, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end

  describe "GET /api/v1/payments" do
    it "returns wallet balance, recent payments, and double-entry ledger entries" do
      Payment.transfer!(sender: sender, recipient: recipient, amount_cents: 5_000, description: "Coffee")

      get "/api/v1/payments", headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["wallet"]["balance_cents"]).to eq(95_000)
      expect(json["payments"].first["formatted_amount"]).to eq("$50.00")
      expect(json["ledger_entries"]).to be_present
    end
  end
end
