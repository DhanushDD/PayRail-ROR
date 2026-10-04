# frozen_string_literal: true

# Interview Handbook - Part 7: The 10 Follow-up Questions Framework (Q170 - Q269)
#
# Implements the 10 follow-up questions framework and the complete worked example
# for Idempotency (Q117) with executable verification and senior insights.
module InterviewHandbook
  module Part7FollowUps
    FOLLOW_UP_MATRIX = {
      0 => { name: "Why important in production?", focus: "Latency, DB load, concurrency, reliability, maintainability" },
      1 => { name: "Most common mistake?", focus: "Tempting wrong approach, concurrency race conditions, safe alternative" },
      2 => { name: "How would you test it?", focus: "One focused positive test + one failure case testing behavior" },
      3 => { name: "What to monitor?", focus: "Latency, query count, queue depth, memory, CPU, error rates, lock waits" },
      4 => { name: "Performance trade-off?", focus: "CPU vs memory vs round-trips vs complexity; no absolutes" },
      5 => { name: "Explain to a junior?", focus: "Simple mental model, one concrete Rails example, one production hazard" },
      6 => { name: "How could I challenge you?", focus: "Defend against edge cases, network drops, crash recovery with evidence" },
      7 => { name: "Rails-specific version?", focus: "ActiveRecord, controllers, callbacks, Sidekiq, Redis, middleware" },
      8 => { name: "What at 10 million records?", focus: "Batching, composite indexes, set-based SQL, connection saturation" },
      9 => { name: "Real-world example?", focus: "Payments, campaigns, webhooks, double-entry ledger, reporting" }
    }.freeze

    WORKED_EXAMPLE_IDEMPOTENCY = {
      why_important: "Retries, duplicate webhooks, and double-clicks are normal. Without idempotency a customer is charged twice.",
      common_mistake: "Checking exists? then create. Two concurrent requests both pass the check. Use a unique index on the key.",
      how_to_test: "Call the endpoint twice with the same key and assert exactly one record created and identical response.",
      what_to_monitor: "Unique-violation rate, duplicate-key cache hits, retry counts, jobs in the dead set.",
      trade_off: "Extra index storage and one cache lookup per request in exchange for guaranteed financial correctness.",
      explain_to_junior: "Like a coat-check ticket: showing the same ticket twice returns the same coat, not a second one.",
      challenge: "What if the worker crashes after the provider charged? Answer: store provider reference, reconcile via webhook/lookup.",
      rails_specific: "add_index :payments, :idempotency_key, unique: true plus rescue ActiveRecord::RecordNotUnique and return existing payment.",
      ten_million_records: "Index must be unique and narrow; expire old keys after 24-72 hours; avoid scanning by key in Ruby.",
      real_world: "POST /payments with an Idempotency-Key header; client retries after a timeout and gets the exact same payment."
    }.freeze

    def self.verify_all
      results = {}

      # 1. Verify Framework definition
      results[:framework_matrix] = {
        complete: FOLLOW_UP_MATRIX.keys.sort == (0..9).to_a,
        total_follow_ups: FOLLOW_UP_MATRIX.size
      }

      # 2. Executable Verification of Worked Example (Q117 Idempotency)
      test_key = "worked_ex_idem_#{SecureRandom.hex(8)}"
      first_rec = IdempotencyRecord.create!(
        key: test_key,
        request_path: "/api/v1/transfers",
        request_params_hash: Digest::SHA256.hexdigest("param_test"),
        response_code: 201,
        response_body: { transfer_id: "TRX-101", amount: 50.00 }.to_json
      )

      # Replay simulation: second request with identical key returns cached response
      replay_found = IdempotencyRecord.find_by(key: test_key)
      cached_body = JSON.parse(replay_found.response_body)

      # Race condition simulation: duplicate insert hits unique index
      duplicate_raised = begin
        IdempotencyRecord.create!(
          key: test_key,
          request_path: "/api/v1/transfers",
          request_params_hash: Digest::SHA256.hexdigest("param_test"),
          response_code: 201,
          response_body: { transfer_id: "TRX-101" }.to_json
        )
        false
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        true
      end

      results[:worked_example_idempotency] = {
        key: test_key,
        persisted_once: IdempotencyRecord.where(key: test_key).count == 1,
        replayed_body_matches: cached_body["transfer_id"] == "TRX-101",
        duplicate_prevented_by_unique_index: duplicate_raised
      }

      results
    end
  end
end
