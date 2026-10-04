# db/seeds.rb for PayRail Payment Engine

puts "🧹 Resetting existing demo data..."
OutboxEvent.delete_all
EmailDelivery.delete_all
SmsRecipient.delete_all
SmsCampaign.delete_all
LedgerEntry.delete_all
Transfer.delete_all
PaymentLink.delete_all
VirtualCard.delete_all
Wallet.delete_all
WebhookDelivery.delete_all
WebhookEndpoint.delete_all
IdempotencyRecord.delete_all
User.delete_all

puts "👥 Creating Users..."
# 1. Primary Demo Account for Accenture Interview
demo_user = User.create!(
  name: "Alex Vance (Accenture Demo)",
  email: "demo@payrail.io",
  payrail_tag: "$accenture_demo",
  password: "password123",
  password_confirmation: "password123",
  role: "customer",
  avatar_color: "#2563EB",
  kyc_verified: true
)

# 2. Alice (Engineering Peer)
alice = User.create!(
  name: "Alice Johnson",
  email: "alice@payrail.io",
  payrail_tag: "$alice",
  password: "password123",
  password_confirmation: "password123",
  role: "customer",
  avatar_color: "#10B981",
  kyc_verified: true
)

# 3. Bob (Consultant & Tech Lead)
bob = User.create!(
  name: "Bob Smith",
  email: "bob@payrail.io",
  payrail_tag: "$bob",
  password: "password123",
  password_confirmation: "password123",
  role: "customer",
  avatar_color: "#8B5CF6",
  kyc_verified: true
)

# 4. Merchant: Nova Coffee Roasters
merchant = User.create!(
  name: "Nova Coffee Roasters",
  email: "billing@novacoffee.com",
  payrail_tag: "$novacoffee",
  password: "password123",
  password_confirmation: "password123",
  role: "merchant",
  avatar_color: "#F59E0B",
  kyc_verified: true
)

puts "💳 Creating Wallets..."
demo_wallet = demo_user.wallets.create!(currency: "USD", balance_cents: 0)
alice_wallet = alice.wallets.create!(currency: "USD", balance_cents: 0)
bob_wallet = bob.wallets.create!(currency: "USD", balance_cents: 0)
merchant_wallet = merchant.wallets.create!(currency: "USD", balance_cents: 0)

puts "🏦 Initializing Bank/Card Rail Deposits..."
# Fund accounts via deposit service
Deposits::ProcessService.call(wallet: demo_wallet, amount_cents: 850000, payment_method: "ach_transfer", description: "Direct Deposit - Tech Consulting Salary")
Deposits::ProcessService.call(wallet: alice_wallet, amount_cents: 420000, payment_method: "card_visa", description: "Initial Card Top-up")
Deposits::ProcessService.call(wallet: bob_wallet, amount_cents: 650000, payment_method: "wire_transfer", description: "Enterprise Consulting Retainer")
Deposits::ProcessService.call(wallet: merchant_wallet, amount_cents: 150000, payment_method: "settlement", description: "Daily Merchant Settlement Batch")

puts "💸 Simulating Real-Time P2P Transfers & Double-Entry Ledger..."
# Demo user pays Alice for project lunch
Transfers::ExecuteService.call(
  sender_wallet: demo_wallet,
  recipient_wallet: alice_wallet,
  amount_cents: 4850,
  category: "dining",
  description: "Team Lunch at Bistro Cafe",
  idempotency_key: "idem_demo_lunch_001"
)

# Bob sends consulting stipend to Demo user
Transfers::ExecuteService.call(
  sender_wallet: bob_wallet,
  recipient_wallet: demo_wallet,
  amount_cents: 120000,
  category: "services",
  description: "Accenture Architecture Review Honorarium",
  idempotency_key: "idem_demo_stipend_002"
)

# Demo user buys coffee at Nova Coffee
Transfers::ExecuteService.call(
  sender_wallet: demo_wallet,
  recipient_wallet: merchant_wallet,
  amount_cents: 1475,
  category: "shopping",
  description: "Cold Brew & Pastry - Nova Coffee",
  idempotency_key: "idem_demo_coffee_003"
)

# Alice reimburses Demo user for cloud hosting
Transfers::ExecuteService.call(
  sender_wallet: alice_wallet,
  recipient_wallet: demo_wallet,
  amount_cents: 7500,
  category: "utilities",
  description: "AWS Cloud Infrastructure Split",
  idempotency_key: "idem_demo_aws_004"
)

puts "💳 Creating Virtual Debit Cards..."
demo_card = demo_user.virtual_cards.create!(
  wallet: demo_wallet,
  cardholder_name: "ALEX VANCE",
  brand: "Visa",
  tier: "Black Metal",
  monthly_limit_cents: 500000,
  spent_this_month_cents: 12450
)

alice_card = alice.virtual_cards.create!(
  wallet: alice_wallet,
  cardholder_name: "ALICE JOHNSON",
  brand: "Mastercard",
  tier: "Platinum",
  monthly_limit_cents: 300000,
  spent_this_month_cents: 4850
)

puts "🔗 Creating Payment Request Links..."
PaymentLink.create!(
  user: demo_user,
  wallet: demo_wallet,
  title: "Custom Software Engineering Consultation",
  description: "1-hour deep dive technical architecture review",
  amount_cents: 15000,
  status: "active"
)

PaymentLink.create!(
  user: merchant,
  wallet: merchant_wallet,
  title: "Specialty Roasted Beans (1kg Bag)",
  description: "Ethiopian Yirgacheffe Single Origin",
  amount_cents: 3200,
  status: "active"
)

puts "🔔 Creating Webhook Endpoints..."
endpoint = demo_user.webhook_endpoints.create!(
  url: "https://api.demo-partner.com/payrail/events"
)

WebhookDelivery.create!(
  webhook_endpoint: endpoint,
  event_type: "transfer.completed",
  payload: {
    event: "transfer.completed",
    reference_id: "TRX-ACCENTURE-INIT-01",
    amount: "$1,200.00",
    sender: "$bob",
    recipient: "$accenture_demo",
    status: "completed",
    timestamp: 1.day.ago.iso8601
  }.to_json,
  response_code: 200,
  status: "delivered"
)

puts "✅ Seed complete!"
puts "--------------------------------------------------"
puts "Demo Credentials for Interview:"
puts "Email: demo@payrail.io"
puts "PayRail Tag: $accenture_demo"
puts "Password: password123"
puts "Wallet Balance: #{demo_wallet.reload.formatted_balance}"
puts "Ledger Entries Count: #{LedgerEntry.count}"
puts "Transfers Count: #{Transfer.count}"
puts "--------------------------------------------------"
