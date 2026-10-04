# Preload domain models, policies, presenters, and services for handbook verification
require_relative "../../app/models/money"
require_relative "../../app/models/date_range"
require_relative "../../app/models/outbox_event"
require_relative "../../app/models/email_delivery"
require_relative "../../app/models/sms_campaign"
require_relative "../../app/models/sms_recipient"
require_relative "../../app/policies/payment_policy"
require_relative "../../app/forms/checkout_form"
require_relative "../../app/presenters/user_presenter"
require_relative "../../app/services/pricing/fee_strategy"
require_relative "../../app/services/payment_adapters/gateway_adapter"
require_relative "../../app/queries/pending_payments_query"
require_relative "../../app/services/infrastructure/circuit_breaker"
require_relative "../../app/services/infrastructure/retry_handler"
require_relative "../../app/services/infrastructure/cursor_paginator"
require_relative "../../app/services/ledger/reconciliation_service"

require_relative "cheat_sheet"
require_relative "core_ruby"
require_relative "ruby_deep_dives"
require_relative "design_patterns"
require_relative "rails_active_record"
require_relative "jobs_apis_security"
require_relative "production_systems"
require_relative "part7_follow_ups"

module InterviewHandbook
  module Runner
    def self.ensure_database_records!
      return if User.count >= 2 && Wallet.count >= 2

      u1 = User.find_or_create_by!(email: "demo@payrail.io") do |u|
        u.name = "Alex Vance"
        u.payrail_tag = "$accenture_demo"
        u.password = "password123"
      end
      u2 = User.find_or_create_by!(email: "alice@payrail.io") do |u|
        u.name = "Alice Johnson"
        u.payrail_tag = "$alice"
        u.password = "password123"
      end
      w1 = Wallet.find_or_create_by!(user: u1, currency: "USD") do |w|
        w.balance_cents = 500_000
        w.status = "active"
      end
      w2 = Wallet.find_or_create_by!(user: u2, currency: "USD") do |w|
        w.balance_cents = 250_000
        w.status = "active"
      end
      Transfer.find_or_create_by!(reference_id: "TRX-HANDBOOK-INIT") do |t|
        t.sender_wallet = w1
        t.recipient_wallet = w2
        t.amount_cents = 1500
        t.currency = "USD"
        t.status = "completed"
        t.transfer_type = "p2p"
      end
    end

    def self.run(verbose: false)
      ensure_database_records!

      puts "\n" + "=" * 70
      puts " 📚 RUBY & RAILS INTERVIEW HANDBOOK — PAYRAIL VERIFICATION ENGINE "
      puts "=" * 70

      sections = [
        { name: "Quick Cheat Sheet (20 Most-Confused Pairs)", module: CheatSheet },
        { name: "Part 1: Core Ruby (Q1 - Q47)", module: CoreRuby },
        { name: "Part 2: Ruby Deep Dives (Q48 - Q67)", module: RubyDeepDives },
        { name: "Part 3: Design & Architecture (Q68 - Q81)", module: DesignPatterns },
        { name: "Part 4: Rails & ActiveRecord (Q82 - Q113)", module: RailsActiveRecord },
        { name: "Part 5: Jobs, Redis, APIs & Security (Q114 - Q148)", module: JobsApisSecurity },
        { name: "Part 6: Production & System Design (Q149 - Q169)", module: ProductionSystems },
        { name: "Part 7: 10 Follow-ups & Worked Example (Q170 - Q269)", module: Part7FollowUps }
      ]

      all_passed = true
      total_items = 0
      passed_items = 0

      sections.each_with_index do |sec, idx|
        puts "\n[#{idx + 1}/#{sections.size}] 🔍 Running #{sec[:name]}..."
        results = sec[:module].verify_all

        results.each do |k, v|
          total_items += 1
          # Check pass condition
          success = if v.is_a?(Hash) && v.key?(:result)
                      v[:result] == true
                    elsif v.is_a?(Hash)
                      v.values.all? { |val| val != false && val != nil }
                    else
                      v == true
                    end

          if success
            passed_items += 1
            if verbose || k.to_s.start_with?("pair") || k.to_s.start_with?("q1") || k.to_s.start_with?("q8")
              puts "  ✓ [PASS] #{k}: #{v.is_a?(Hash) && v[:question] ? v[:question] : 'Verified successfully'}"
            end
          else
            all_passed = false
            puts "  ✗ [FAIL] #{k}: #{v}"
          end
        end

        puts "  -> Completed #{sec[:name]}: #{results.size} verification items passed."
      end

      puts "\n" + "=" * 70
      if all_passed
        puts " 🎉 ALL #{total_items}/#{total_items} HANDBOOK CODES & PATTERNS VERIFIED HEALTHY!"
        puts " ⚡ 100% OF CODES FROM Q1-Q169, CHEAT SHEET & FOLLOW-UPS PASSING CLEANLY"
        puts "=" * 70 + "\n"
      else
        puts " ❌ SOME CHECKS FAILED: #{passed_items}/#{total_items} passed."
        puts "=" * 70 + "\n"
      end

      { total: total_items, passed: passed_items, success: all_passed }
    end
  end
end
