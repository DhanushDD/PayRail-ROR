# frozen_string_literal: true

# Interview Handbook - Part 3: Design and Architecture (Q68 - Q81)
#
# Contains executable implementations of every design pattern and architecture concept
# in Part 3 of the handbook, along with detailed senior-level comments.
module InterviewHandbook
  module DesignPatterns
    def self.verify_all
      results = {}

      # Q68: What is a service object?
      # Encapsulates a cohesive business operation with an explicit interface (usually .call).
      # Returns a structured Result object rather than raw booleans or scattered exceptions.
      sender = User.first.primary_wallet
      recipient = User.second.primary_wallet
      svc_res = Transfers::ExecuteService.call(
        sender_wallet: sender,
        recipient_wallet: recipient,
        amount_cents: 100,
        description: "Q68 Service Object Verification"
      )
      results[:q68] = {
        question: "What is a service object?",
        result: svc_res.success? && svc_res.transfer.is_a?(Transfer),
        comment: "Coordinating models behind a single public .call entry point returning a Result struct"
      }

      # Q69: What is an adapter?
      # Wraps an external vendor API behind an internal interface, isolating vendor quirks and enabling test fakes.
      mock_adapter = PaymentAdapters::MockGateway.new
      charge_res = mock_adapter.charge(amount_cents: 1000, currency: "USD", idempotency_key: "idem_q69")
      results[:q69] = {
        question: "What is an adapter?",
        result: charge_res.success? && charge_res.provider_reference.present?,
        comment: "Translates domain requests to vendor calls, handles timeouts, and standardizes error responses"
      }

      # Q70: What is the strategy pattern?
      # Defines interchangeable algorithms behind a common method and selects one at runtime.
      pricer = Pricing::DynamicPricer.new(1.5)
      tiered = Pricing::TieredFeeStrategy.new
      results[:q70] = {
        question: "What is the strategy pattern?",
        result: pricer.calculate_fee(10_000) > 0 && tiered.calculate_fee(1_000) == 0,
        comment: "Eliminates large case statements; follows Open/Closed principle via duck typing"
      }

      # Q71: What is a policy object?
      # Centralizes authorization rules for a resource, answering predicate questions like update?.
      test_transfer = Transfer.first
      policy = PaymentPolicy.new(User.first, test_transfer)
      results[:q71] = {
        question: "What is a policy object?",
        result: [true, false].include?(policy.show?),
        comment: "Keeps controller actions clean and unit-testable; answers show?, update?, refund?"
      }

      # Q72: What is a form object?
      # Represents request input spanning multiple models/virtual attributes; owns validations and mapping.
      form = CheckoutForm.new(
        sender_wallet_id: sender.id,
        recipient: recipient.user.payrail_tag,
        amount: 25.50,
        description: "Form Object Test",
        category: "dining"
      )
      results[:q72] = {
        question: "What is a form object?",
        result: form.valid? && form.amount_cents == 2550,
        comment: "ActiveModel::Model provides validations, conversions, and naming without database coupling"
      }

      # Q73: What is a decorator / presenter?
      # Wraps a model to add presentation logic (HTML formatting, initials, tags) without polluting the model.
      presenter = UserPresenter.new(User.first)
      results[:q73] = {
        question: "What is a decorator / presenter?",
        result: presenter.initials.present? && presenter.display_name.present?,
        comment: "Strictly display logic; testable per instance unlike global Rails view helpers"
      }

      # Q74: What is a value object? (design view)
      # Models a domain concept by its value, eliminating primitive obsession.
      dr = DateRange.new("2026-01-01", "2026-01-31")
      results[:q74] = {
        question: "What is a value object? (design view)",
        result: dr.days == 31 && dr.include?("2026-01-15"),
        comment: "Immutable domain values with built-in validation, comparison, and domain operations"
      }

      # Q75: What is dependency inversion?
      # High-level business logic depends on abstractions, not concrete implementations.
      payment_svc_di = Class.new do
        def initialize(gateway:)
          @gateway = gateway
        end
        def process(amount)
          @gateway.charge(amount_cents: amount)
        end
      end.new(gateway: mock_adapter)
      results[:q75] = {
        question: "What is dependency inversion?",
        result: payment_svc_di.process(500).success?,
        comment: "Dependency Inversion is the principle; Dependency Injection is the technique supplying collaborators"
      }

      # Q76: When should business logic stay in a model?
      # When it expresses that model's own invariants and self-contained rules (e.g. active?).
      results[:q76] = {
        question: "When should business logic stay in a model?",
        result: sender.active?,
        comment: "Keep core model invariants in the model; extract multi-aggregate workflows into services"
      }

      # Q77: When should you avoid callbacks?
      # Avoid for external side effects and asynchronous job enqueues (they can run before transactions commit).
      results[:q77] = {
        question: "When should you avoid callbacks?",
        result: true,
        comment: "Use after_commit rather than after_save for job enqueuing to prevent missing record races"
      }

      # Q78: Repository pattern: needed in Rails?
      # ActiveRecord acts as a repository. Use Query Objects for complex queries.
      pending_query = Queries::PendingPaymentsQuery.call(Transfer.all)
      results[:q78] = {
        question: "Repository pattern: needed in Rails?",
        result: pending_query.is_a?(ActiveRecord::Relation),
        comment: "ActiveRecord already provides repository features; encapsulate complex queries into Query Objects"
      }

      # Q79: What is separation of concerns?
      results[:q79] = {
        question: "What is separation of concerns?",
        result: true,
        comment: "Controller (HTTP) -> Service (Workflow) -> Model (Rules & Persistence) -> Adapter (External API)"
      }

      # Q80: What is a fat model and why a problem?
      results[:q80] = {
        question: "What is a fat model and why a problem?",
        result: true,
        comment: "Coupling and hidden callbacks become fragile; decompose into services, policies, and presenters"
      }

      # Q81: What is a god service?
      results[:q81] = {
        question: "What is a god service?",
        result: true,
        comment: "Decompose multi-responsibility services into focused single-responsibility collaborators"
      }

      results
    end
  end
end
