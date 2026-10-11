require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations and normalization" do
    it "creates a valid user and normalizes email and payrail_tag" do
      user = User.create!(
        name: "Test User",
        email: "  TEST@PayRail.io ",
        payrail_tag: "testuser",
        password: "password123",
        password_confirmation: "password123"
      )

      expect(user).to be_persisted
      expect(user.email).to eq("test@payrail.io")
      expect(user.payrail_tag).to eq("$testuser")
      expect(user.api_key).to start_with("pr_live_")
    end

    it "validates uniqueness of email and payrail_tag" do
      User.create!(
        name: "First User",
        email: "unique@payrail.io",
        payrail_tag: "$unique",
        password: "password123"
      )

      duplicate = User.new(
        name: "Duplicate User",
        email: "UNIQUE@payrail.io",
        payrail_tag: "unique",
        password: "password123"
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include("has already been taken")
      expect(duplicate.errors[:payrail_tag]).to include("has already been taken")
    end
  end

  describe ".find_by_identifier" do
    let!(:user) do
      User.create!(
        name: "Dhanush Daran",
        email: "dhanush@payrail.io",
        payrail_tag: "$dhanush",
        password: "password123"
      )
    end

    it "finds user by case-insensitive email" do
      expect(User.find_by_identifier("DHANUSH@payrail.io").first).to eq(user)
    end

    it "finds user by payrail_tag with or without $ prefix" do
      expect(User.find_by_identifier("$dhanush").first).to eq(user)
      expect(User.find_by_identifier("dhanush").first).to eq(user)
    end
  end

  describe "#record_sign_in!" do
    it "increments sign_in_count and sets last_sign_in_at" do
      user = User.create!(
        name: "Login User",
        email: "login@payrail.io",
        payrail_tag: "$loginuser",
        password: "password123"
      )

      expect { user.record_sign_in! }.to change { user.reload.sign_in_count }.by(1)
      expect(user.last_sign_in_at).to be_present
    end
  end
end
