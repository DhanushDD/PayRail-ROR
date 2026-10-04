# frozen_string_literal: true

require "test_helper"
require_relative "../../lib/interview_handbook/runner"

class InterviewHandbookTest < ActiveSupport::TestCase
  setup do
    InterviewHandbook::Runner.ensure_database_records!
  end

  test "all 191 handbook codes and patterns verify with 0 failures" do
    result = InterviewHandbook::Runner.run(verbose: false)
    assert result[:success], "Expected all handbook codes to pass verification"
    assert_equal result[:total], result[:passed], "All #{result[:total]} items must pass"
  end

  test "cheat sheet pairs verify equality, identity, and isolation rules" do
    cheat_sheet_results = InterviewHandbook::CheatSheet.verify_all
    assert cheat_sheet_results[:pair1_equality][:value_equals]
    assert cheat_sheet_results[:pair1_equality][:eql_strict]
    assert cheat_sheet_results[:pair1_equality][:equal_identity]
    assert cheat_sheet_results[:pair2_dup_vs_clone][:clone_keeps_singleton]
    assert cheat_sheet_results[:pair4_proc_vs_lambda][:lambda_strict_arity]
  end

  test "value objects (Money, DateRange) enforce invariants and immutability" do
    m1 = Money.new(1500, "USD")
    m2 = Money.new(1500, "USD")
    assert_equal m1, m2
    assert m1.eql?(m2)
    assert_equal m1.hash, m2.hash
    assert m1.frozen?
    assert_equal "$15.00", m1.format

    m3 = m1 + Money.new(500, "USD")
    assert_equal 2000, m3.amount_cents

    assert_raises(ArgumentError) do
      m1 + Money.new(500, "EUR")
    end

    dr = DateRange.new("2026-01-01", "2026-01-10")
    assert dr.include?("2026-01-05")
    refute dr.include?("2026-01-15")
  end

  test "circuit breaker transitions between closed, open, and half-open" do
    cb = Infrastructure::CircuitBreaker.new(name: "test_circuit", failure_threshold: 2, cooldown_period: 0.05)
    assert_equal :closed, cb.state

    # 1st failure
    assert_raises(RuntimeError) { cb.run { raise "failure 1" } }
    assert_equal :closed, cb.state

    # 2nd failure triggers open
    assert_raises(RuntimeError) { cb.run { raise "failure 2" } }
    assert_equal :open, cb.state

    # Immediate next call fails fast with CircuitBreakerOpenError
    assert_raises(Infrastructure::CircuitBreakerOpenError) { cb.run { "blocked" } }

    # Sleep past cooldown period
    sleep 0.06
    # Half-open probe succeeds and closes breaker
    probe = cb.run { "probe_ok" }
    assert_equal "probe_ok", probe
    assert_equal :closed, cb.state
  end

  test "outbox pattern atomically persists business change and event record" do
    assert_difference -> { OutboxEvent.count } => 1 do
      ApplicationRecord.transaction do
        OutboxEvent.create!(
          event_type: "transfer.completed",
          aggregate_type: "Transfer",
          aggregate_id: "TRX-TEST-1",
          payload: { amount_cents: 2500, currency: "USD" },
          status: "pending"
        )
      end
    end

    event = OutboxEvent.last
    assert_equal "pending", event.status
    event.mark_published!
    assert_equal "published", event.status
    assert event.published_at.present?
  end

  test "reconciliation service detects amount mismatches and missing records" do
    transfer = Transfer.completed.first || Transfer.create!(
      sender_wallet: Wallet.first,
      recipient_wallet: Wallet.second,
      amount_cents: 1000,
      currency: "USD",
      transfer_type: "p2p",
      status: "completed"
    )

    # Provider report with mismatched amount
    provider_data = [
      { id: transfer.reference_id, amount_cents: 9999, status: "succeeded" }
    ]

    report = Ledger::ReconciliationService.call(provider_records: provider_data)
    refute report.reconciled?
    assert report.discrepancies.any? { |d| d.type == :amount_mismatch }
  end
end
