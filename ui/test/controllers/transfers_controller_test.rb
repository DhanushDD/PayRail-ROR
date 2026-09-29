require "test_helper"

class TransfersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sender = User.find_by(email: "demo@payrail.io") || User.create!(
      name: "Demo User",
      email: "demo_test@payrail.io",
      payrail_tag: "$demo_test",
      password: "password123"
    )
    @sender_wallet = @sender.primary_wallet || @sender.wallets.create!(currency: "USD", balance_cents: 50000)

    @recipient = User.find_by(email: "alice@payrail.io") || User.create!(
      name: "Alice Peer",
      email: "alice_test@payrail.io",
      payrail_tag: "$alice_test",
      password: "password123"
    )
    @recipient_wallet = @recipient.primary_wallet || @recipient.wallets.create!(currency: "USD", balance_cents: 20000)
  end

  test "redirects unauthenticated users to login" do
    get dashboard_path
    assert_redirected_to login_path
  end

  test "can sign in with 1-click demo access" do
    post login_path, params: { demo_user_id: @sender.id }
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_response :success
  end

  test "authenticated user can execute transfer to peer" do
    # Sign in
    post login_path, params: { demo_user_id: @sender.id }

    # Send $25.00 to Alice
    assert_difference "Transfer.count", 1 do
      post transfers_path, params: {
        recipient: @recipient.payrail_tag,
        amount: "25.00",
        description: "Integration Test Payment"
      }
    end

    created_transfer = Transfer.last
    assert_redirected_to transfer_path(created_transfer.reference_id)
    follow_redirect!
    assert_response :success
    assert_select "div", text: /Payment Settled Successfully/
  end
end
