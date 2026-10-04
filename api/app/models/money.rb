# frozen_string_literal: true

# Money Value Object (Demonstrating Q12, Q42, Q74, Q152 from Ruby & Rails Interview Handbook)
#
# Key Characteristics:
# 1. Immutable Value Object: Frozen upon initialization (Q42, Q74).
# 2. Integer Minor Units: Stores amounts as integer cents to avoid floating-point rounding errors (Q152).
# 3. Value Equality: Implements both `==` and `eql?` alongside `hash` (Q11, Q12) so instances
#    with the same amount and currency are equal and behave correctly in Hashes, Sets, and `uniq`.
# 4. Domain Operations: Supports addition, subtraction, and comparison while enforcing currency match invariants.
class Money
  include Comparable

  attr_reader :amount_cents, :currency

  def initialize(amount_cents, currency = "USD")
    @amount_cents = amount_cents.to_i
    @currency = currency.to_s.upcase.freeze
    freeze # Enforce immutability
  end

  # Value equality comparison (Q11)
  def ==(other)
    other.is_a?(Money) &&
      amount_cents == other.amount_cents &&
      currency == other.currency
  end

  # Strict equality for Hash key lookup (Q11, Q12)
  def eql?(other)
    other.instance_of?(Money) &&
      amount_cents == other.amount_cents &&
      currency == other.currency
  end

  # Hash code agreement with eql? (Q12)
  # When two objects are eql?, their hash codes MUST be identical.
  def hash
    [amount_cents, currency].hash
  end

  # Comparable operator <=>
  def <=>(other)
    return nil unless other.is_a?(Money)
    assert_same_currency!(other)
    amount_cents <=> other.amount_cents
  end

  # Addition of money with currency check
  def +(other)
    assert_same_currency!(other)
    Money.new(amount_cents + other.amount_cents, currency)
  end

  # Subtraction of money with currency check
  def -(other)
    assert_same_currency!(other)
    Money.new(amount_cents - other.amount_cents, currency)
  end

  # Multiplication by scalar
  def *(factor)
    Money.new((amount_cents * factor).round, currency)
  end

  # Formatted currency string
  def format
    symbol = case currency
             when "USD" then "$"
             when "EUR" then "€"
             when "GBP" then "£"
             when "INR" then "₹"
             else "#{currency} "
             end
    Kernel.format("#{symbol}%.2f", amount_cents / 100.0)
  end

  def to_s
    format
  end

  private

  def assert_same_currency!(other)
    unless currency == other.currency
      raise ArgumentError, "Currency mismatch: cannot operate on #{currency} and #{other.currency}"
    end
  end
end
