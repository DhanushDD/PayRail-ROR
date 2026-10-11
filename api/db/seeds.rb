# Clean Seed Data for PayRail Payment & Authentication App
puts "Seeding PayRail demo users, wallets, and sample payments..."

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

# Fund Dhanush's wallet and create sample P2P payments
dhanush.wallet.deposit!(150_000, description: "Initial Bank Deposit")
Payment.transfer!(sender: dhanush, recipient: alice, amount_cents: 12_500, description: "Team Lunch Split")
Payment.transfer!(sender: bob, recipient: dhanush, amount_cents: 8_000, description: "API Consulting Fee")

puts "Seeded #{User.count} users, #{Wallet.count} wallets, #{Payment.count} payments, and #{LedgerEntry.count} ledger entries."
