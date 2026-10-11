# Clean Seed Data for PayRail Payment Gateway & Authentication App
puts "Seeding PayRail demo users, wallets, and sample gateway payments..."

WebhookEvent.destroy_all
LedgerEntry.destroy_all
Payment.destroy_all
Wallet.destroy_all
User.destroy_all

dhanush = User.create!(
  name: "Dhanush Daran",
  email: "demo@payrail.io",
  payrail_tag: "$dhanush",
  password: "password123",
  password_confirmation: "password123",
  role: "admin",
  avatar_color: "#003087",
  phone_number: "+91 9659747699"
)

alice = User.create!(
  name: "Alice Rivera",
  email: "alice@payrail.io",
  payrail_tag: "$alice",
  password: "password123",
  password_confirmation: "password123",
  role: "customer",
  avatar_color: "#10B981",
  phone_number: "+1 415-555-0101"
)

bob = User.create!(
  name: "Bob Vance",
  email: "bob@payrail.io",
  payrail_tag: "$bob",
  password: "password123",
  password_confirmation: "password123",
  role: "customer",
  avatar_color: "#3B82F6",
  phone_number: "+1 415-555-0102"
)

# 1. Fund Dhanush's wallet
dhanush.wallet.deposit!(150_000, description: "Initial Bank Deposit")

# 2. Sample Instant P2P Transfer
Payment.transfer!(sender: dhanush, recipient: alice, amount_cents: 12_500, description: "Team Lunch Split")

# 3. Sample Gateway Authorize + Capture (with 2.9% + $0.30 gateway fee)
auth_captured = Payment.authorize!(sender: bob, recipient: dhanush, amount_cents: 10_000, description: "SaaS Enterprise Plan #101")
auth_captured.capture!

# 4. Sample Pending Gateway Authorization Hold (ready to Capture or Void in UI)
Payment.authorize!(sender: dhanush, recipient: alice, amount_cents: 5_000, description: "Cloud Hosting Pre-Auth Hold")

puts "Seeded #{User.count} users, #{Wallet.count} wallets, #{Payment.count} payments, and #{LedgerEntry.count} ledger entries."
