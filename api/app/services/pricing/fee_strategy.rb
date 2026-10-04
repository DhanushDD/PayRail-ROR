# frozen_string_literal: true

# Strategy Pattern for Transaction Fees (Demonstrating Q70 from Ruby & Rails Interview Handbook)
#
# Key Architectural Features:
# 1. Open/Closed Principle: New fee calculation algorithms can be introduced without modifying existing case statements.
# 2. Duck Typing (Q4): Any object that responds to `#calculate_fee(amount_cents)` is a valid fee strategy.
# 3. Testability: Strategies are easily swapped or mocked in tests via dependency injection (Q43).
module Pricing
  # Flat fee strategy: charges a fixed amount regardless of transaction size
  class FlatFeeStrategy
    attr_reader :flat_cents

    def initialize(flat_cents = 25)
      @flat_cents = flat_cents
    end

    def calculate_fee(amount_cents)
      @flat_cents
    end
  end

  # Percentage-based tiered fee strategy
  class TieredFeeStrategy
    def calculate_fee(amount_cents)
      if amount_cents < 5_000 # Under $50
        0 # Free tier
      elsif amount_cents < 50_000 # Under $500
        (amount_cents * 0.01).round # 1.0%
      else
        (amount_cents * 0.005).round # 0.5% volume discount
      end
    end
  end

  # Dynamic pricer strategy: considers peak hours or merchant categories
  class DynamicPricer
    attr_reader :surge_multiplier

    def initialize(surge_multiplier = 1.25)
      @surge_multiplier = surge_multiplier
    end

    def calculate_fee(amount_cents)
      base_fee = (amount_cents * 0.015).round # 1.5% base
      (base_fee * @surge_multiplier).round
    end
  end
end
