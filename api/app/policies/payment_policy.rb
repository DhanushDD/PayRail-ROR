# frozen_string_literal: true

# PaymentPolicy Object (Demonstrating Q71 & Q125 - Policy Objects & Authorization)
#
# Key Architectural Features:
# 1. Separation of Concerns: Extracts authorization logic out of controllers and models.
# 2. Unit-Testable: Pure PORO taking (user, record), allowing fast, isolated testing.
# 3. IDOR Defense (Q125): Guarantees callers cannot read or refund transactions belonging to other users.
class PaymentPolicy
  attr_reader :user, :payment

  def initialize(user, payment)
    @user = user
    @payment = payment
  end

  # Can the user view this payment?
  # User can view if they are admin or owner of either sender or recipient wallet.
  def show?
    user.role == "admin" || participant?
  end

  # Can the user update this payment?
  # Financial ledger entries are immutable; updates are generally forbidden.
  def update?
    user.role == "admin" && payment.status == "pending"
  end

  # Can the user request a refund for this payment?
  def refund?
    return false unless payment.status == "completed"
    user.role == "admin" || sender?
  end

  # Can the user cancel a pending payment?
  def cancel?
    payment.status == "pending" && (user.role == "admin" || sender?)
  end

  private

  def sender?
    payment.sender_wallet&.user_id == user.id
  end

  def recipient?
    payment.recipient_wallet&.user_id == user.id
  end

  def participant?
    sender? || recipient?
  end
end
