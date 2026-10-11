# Clean Seed Data for PayRail Authentication
puts "Seeding PayRail demo users..."

User.destroy_all

demo_users = [
  {
    name: "Dhanush Daran",
    email: "demo@payrail.io",
    payrail_tag: "$dhanush",
    password: "password123",
    password_confirmation: "password123",
    role: "admin",
    avatar_color: "#003087",
    phone_number: "+91 9659747699"
  },
  {
    name: "Alice Rivera",
    email: "alice@payrail.io",
    payrail_tag: "$alice",
    password: "password123",
    password_confirmation: "password123",
    role: "customer",
    avatar_color: "#10B981",
    phone_number: "+1 415-555-0101"
  },
  {
    name: "Bob Vance",
    email: "bob@payrail.io",
    payrail_tag: "$bob",
    password: "password123",
    password_confirmation: "password123",
    role: "customer",
    avatar_color: "#3B82F6",
    phone_number: "+1 415-555-0102"
  }
]

demo_users.each do |attrs|
  User.create!(attrs)
end

puts "Seeded #{User.count} users successfully."
