require "rails_helper"

RSpec.describe "API V1 Payments & Payment Gateway Lifecycle", type: :request do
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

  describe "Payment Gateway 2-Step Workflow: Authorize -> Capture / Void -> Refund" do
    it "places an authorization hold and then captures funds with 2.9% + $0.30 gateway fee" do
      # Step 1: Authorize $100.00 (10,000 cents)
      post "/api/v1/payments/authorize",
           params: { recipient: "$alice", amount: 100.00, description: "Order #500" },
           headers: headers

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      payment_id = json["payment"]["id"]

      expect(json["payment"]["status"]).to eq("authorized")
      expect(json["payment"]["authorization_code"]).to start_with("AUTH-")
      expect(json["payment"]["fee_cents"]).to eq(320) # 2.9% of 10000 (290) + 30 = 320 cents ($3.20)
      expect(json["payment"]["net_amount_cents"]).to eq(9680) # $96.80 net to merchant

      # Sender available balance reduced by $100, held_balance increased by $100; recipient not credited yet
      expect(sender.wallet.reload.balance_cents).to eq(90_000)
      expect(sender.wallet.held_balance_cents).to eq(10_000)
      expect(recipient.wallet.reload.balance_cents).to eq(100_000)

      # Step 2: Capture the authorized payment
      expect {
        post "/api/v1/payments/#{payment_id}/capture", headers: headers
      }.to change(LedgerEntry, :count).by(2)
       .and have_enqueued_job(PaymentNotificationJob)

      expect(response).to have_http_status(:ok)
      capture_json = JSON.parse(response.body)
      expect(capture_json["payment"]["status"]).to eq("captured")

      # Hold is released and merchant receives net amount ($96.80)
      expect(sender.wallet.reload.held_balance_cents).to eq(0)
      expect(recipient.wallet.reload.balance_cents).to eq(109_680)
    end

    it "allows voiding an authorized payment and releases held funds back to customer" do
      payment = Payment.authorize!(sender: sender, recipient: recipient, amount_cents: 20_000, description: "Hotel Hold")
      expect(sender.wallet.reload.balance_cents).to eq(80_000)
      expect(sender.wallet.held_balance_cents).to eq(20_000)

      post "/api/v1/payments/#{payment.id}/void", headers: headers
      expect(response).to have_http_status(:ok)

      expect(payment.reload.status).to eq("voided")
      expect(sender.wallet.reload.balance_cents).to eq(100_000)
      expect(sender.wallet.held_balance_cents).to eq(0)
    end

    it "returns 402 payment_required when gateway declines card token" do
      post "/api/v1/payments/authorize",
           params: { recipient: "$alice", amount: 50.00, payment_method_token: "tok_declined" },
           headers: headers

      expect(response).to have_http_status(:payment_required)
    end
  end

  describe "POST /api/v1/webhooks/gateway (HMAC-SHA256 Verified Gateway Webhooks)" do
    it "verifies X-PayRail-Signature, stores idempotent WebhookEvent, and enqueues GatewayWebhookJob" do
      payment = Payment.authorize!(sender: sender, recipient: recipient, amount_cents: 10_000, description: "Webhook Capture")

      payload = {
        event_id: "evt_gw_1001",
        event_type: "payment.captured",
        gateway_transaction_id: payment.gateway_transaction_id,
        reference_id: payment.reference_id
      }.to_json

      signature = PaymentGatewayService.compute_signature(payload)

      expect {
        post "/api/v1/webhooks/gateway",
             params: payload,
             headers: { "CONTENT_TYPE" => "application/json", "X-PayRail-Signature" => signature }
      }.to change(WebhookEvent, :count).by(1)
       .and have_enqueued_job(GatewayWebhookJob)

      expect(response).to have_http_status(:accepted)

      # Execute job to verify async webhook settles the payment
      GatewayWebhookJob.perform_now(WebhookEvent.last.id)
      expect(payment.reload.status).to eq("captured")
      expect(WebhookEvent.last.status).to eq("processed")
    end

    it "rejects webhook with invalid HMAC signature" do
      post "/api/v1/webhooks/gateway",
           params: { event_id: "evt_bad", event_type: "payment.captured" }.to_json,
           headers: { "CONTENT_TYPE" => "application/json", "X-PayRail-Signature" => "invalid_sig" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/payments (Instant P2P Transfer & Idempotency)" do
    it "transfers funds atomically, records debit & credit ledger entries, and enqueues PaymentNotificationJob" do
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

      expect {
        post "/api/v1/payments",
             params: { recipient: "$alice", amount: 100.00, description: "Retry Attempt" },
             headers: idem_headers
      }.not_to change { sender.reload.balance_cents }
    end
  end

  describe "POST /api/v1/payments/:id/refund (Payment Reversal & Refund)" do
    it "allows recipient to refund a completed payment and reverses wallet balances & ledger entries" do
      payment = Payment.transfer!(sender: sender, recipient: recipient, amount_cents: 20_000, description: "Order #101")
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
end
