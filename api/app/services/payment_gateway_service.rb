class PaymentGatewayService
  WEBHOOK_SECRET = ENV.fetch("PAYRAIL_WEBHOOK_SECRET", "whsec_payrail_secret_key_2026")
  GATEWAY_FEE_PERCENT = 0.029 # 2.9%
  GATEWAY_FIXED_FEE_CENTS = 30 # $0.30

  class GatewayDeclinedError < StandardError; end

  # Calculate standard payment gateway processing fee (2.9% + $0.30)
  def self.calculate_fee_cents(amount_cents)
    return 0 if amount_cents <= 0
    ((amount_cents * GATEWAY_FEE_PERCENT).round + GATEWAY_FIXED_FEE_CENTS)
  end

  # Simulate external gateway card/payment-method authorization
  def self.authorize_charge(amount_cents:, currency: "USD", payment_method_token: "tok_visa_4242")
    if payment_method_token == "tok_declined"
      raise GatewayDeclinedError, "Card declined by issuing bank (insufficient_funds)"
    end

    {
      gateway_provider: "payrail_gateway",
      gateway_transaction_id: "gw_txn_#{SecureRandom.hex(6)}",
      authorization_code: "AUTH-#{SecureRandom.random_number(100000..999999)}",
      payment_method_token: payment_method_token.presence || "tok_visa_4242",
      status: "authorized",
      authorized_at: Time.current
    }
  end

  # Verify HMAC-SHA256 signature on incoming gateway webhooks
  def self.verify_webhook_signature!(payload_body, signature_header)
    return false if signature_header.blank?
    expected = compute_signature(payload_body)
    ActiveSupport::SecurityUtils.secure_compare(expected, signature_header.to_s)
  end

  def self.compute_signature(payload_body)
    OpenSSL::HMAC.hexdigest("SHA256", WEBHOOK_SECRET, payload_body.to_s)
  end
end
