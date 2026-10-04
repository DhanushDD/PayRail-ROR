# frozen_string_literal: true

# Payment Adapters (Demonstrating Q43, Q69, Q75, Q119 from Ruby & Rails Interview Handbook)
#
# Key Architectural Features:
# 1. Adapter Pattern (Q69): Wraps external vendor APIs behind PayRail's internal domain interface.
# 2. Dependency Inversion (Q75): High-level payment workflows depend on the gateway abstraction, not Stripe/PayPal directly.
# 3. Fault Tolerance & Error Translation (Q119): Converts vendor HTTP errors or network timeouts into domain exceptions.
module PaymentAdapters
  # Standardized result object returned by all payment adapters (Q68)
  ChargeResult = Struct.new(:success?, :provider_reference, :status, :error_message, :raw_response, keyword_init: true)

  class AdapterError < StandardError; end
  class TransientGatewayError < AdapterError; end # Safe to retry (5xx, timeouts, 429)
  class PermanentGatewayError < AdapterError; end # Do not retry (4xx card declined, invalid key)

  # Real-world styled Stripe Gateway Adapter
  class StripeGateway
    attr_reader :api_key, :timeout_seconds

    def initialize(api_key: ENV.fetch("STRIPE_API_KEY", "sk_test_mock"), timeout_seconds: 5)
      @api_key = api_key
      @timeout_seconds = timeout_seconds
    end

    def charge(amount_cents:, currency: "USD", idempotency_key: nil, metadata: {})
      # In production this calls Stripe::PaymentIntent.create(..., idempotency_key: idempotency_key)
      # For demonstration / testing, it simulates external provider execution:
      if amount_cents <= 0
        raise PermanentGatewayError, "Invalid charge amount: #{amount_cents}"
      end

      # Simulates success with external reference
      provider_ref = "ch_stripe_#{SecureRandom.hex(12)}"
      ChargeResult.new(
        success?: true,
        provider_reference: provider_ref,
        status: "succeeded",
        error_message: nil,
        raw_response: { id: provider_ref, amount: amount_cents, currency: currency, status: "succeeded" }
      )
    end
  end

  # Fast in-memory Mock Gateway for reliable unit & integration tests
  class MockGateway
    attr_accessor :should_fail, :should_timeout, :fail_with_transient

    def initialize(should_fail: false, should_timeout: false, fail_with_transient: false)
      @should_fail = should_fail
      @should_timeout = should_timeout
      @fail_with_transient = fail_with_transient
      @processed_charges = []
    end

    def charge(amount_cents:, currency: "USD", idempotency_key: nil, metadata: {})
      if @should_timeout
        raise TransientGatewayError, "Connection to payment gateway timed out (Simulated Net::OpenTimeout)"
      end

      if @should_fail
        if @fail_with_transient
          raise TransientGatewayError, "HTTP 503 Service Unavailable"
        else
          raise PermanentGatewayError, "Card declined: insufficient funds"
        end
      end

      ref = "mock_tx_#{SecureRandom.hex(8)}"
      @processed_charges << { ref: ref, amount_cents: amount_cents, idempotency_key: idempotency_key }

      ChargeResult.new(
        success?: true,
        provider_reference: ref,
        status: "succeeded",
        error_message: nil,
        raw_response: { id: ref, amount: amount_cents, idempotency_key: idempotency_key }
      )
    end

    def charges_count
      @processed_charges.size
    end
  end
end
