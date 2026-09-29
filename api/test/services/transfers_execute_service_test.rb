require "test_helper"

class TransfersExecuteServiceTest < ActiveSupport::TestCase
  setup do
    @sender_user = User.create!(
      name: "Sender Test",
      email: "sender_test_#{SecureRandom.hex(4)}@payrail.io",
      payrail_tag: "$sender_#{SecureRandom.hex(4)}",
      password: "password123"
    )
    @sender_wallet = @sender_user.wallets.create!(currency: "USD", balance_cents: 50000)

    @recipient_user = User.create!(
      name: "Recipient Test",
      email: "recipient_test_#{SecureRandom.hex(4)}@payrail.io",
      payrail_tag: "$recipient_#{SecureRandom.hex(4)}",
      password: "password123"
    )
    @recipient_wallet = @recipient_user.wallets.create!(currency: "USD", balance_cents: 10000)
  end

  test "successfully executes transfer and creates balanced double-entry ledger records" do
    result = Transfers::ExecuteService.call(
      sender_wallet: @sender_wallet,
      recipient_wallet: @recipient_wallet,
      amount_cents: 15000,
      description: "Unit Test P2P Transfer"
    )

    assert result.success?, "Expected transfer to succeed but failed with #{result.error_message}"
    assert_not_nil result.transfer

    # Check updated wallet balances
    assert_equal 35000, @sender_wallet.reload.balance_cents
    assert_equal 25000, @recipient_wallet.reload.balance_cents

    # Check double-entry ledger integrity
    ledger_entries = result.transfer.ledger_entries
    assert_equal 2, ledger_entries.count

    debit_entry = ledger_entries.find_by(entry_type: "debit")
    credit_entry = ledger_entries.find_by(entry_type: "credit")

    assert_not_nil debit_entry
    assert_not_nil credit_entry
    assert_equal @sender_wallet.id, debit_entry.wallet_id
    assert_equal @recipient_wallet.id, credit_entry.wallet_id
    assert_equal 15000, debit_entry.amount_cents
    assert_equal 15000, credit_entry.amount_cents
    assert_equal 35000, debit_entry.balance_after_cents
    assert_equal 25000, credit_entry.balance_after_cents

    # Invariant: debits == credits
    assert_equal debit_entry.amount_cents, credit_entry.amount_cents
  end

  test "fails and rolls back when sender has insufficient funds" do
    result = Transfers::ExecuteService.call(
      sender_wallet: @sender_wallet,
      recipient_wallet: @recipient_wallet,
      amount_cents: 999999, # more than available 50000
      description: "Attempted Overdraft"
    )

    assert_not result.success?
    assert_equal "insufficient_funds_error", result.error_code

    # Balances must remain unchanged
    assert_equal 50000, @sender_wallet.reload.balance_cents
    assert_equal 10000, @recipient_wallet.reload.balance_cents
  end

  test "fails when sender and recipient are the same wallet" do
    result = Transfers::ExecuteService.call(
      sender_wallet: @sender_wallet,
      recipient_wallet: @sender_wallet,
      amount_cents: 1000
    )

    assert_not result.success?
    assert_equal "invalid_wallet_error", result.error_code
  end
end
