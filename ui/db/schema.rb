# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_11_000001) do
  create_table "ledger_entries", force: :cascade do |t|
    t.integer "payment_id", null: false
    t.integer "wallet_id", null: false
    t.string "entry_type", null: false
    t.bigint "amount_cents", null: false
    t.bigint "balance_after_cents", null: false
    t.string "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payment_id"], name: "index_ledger_entries_on_payment_id"
    t.index ["wallet_id", "created_at"], name: "index_ledger_entries_on_wallet_id_and_created_at"
    t.index ["wallet_id"], name: "index_ledger_entries_on_wallet_id"
  end

  create_table "payments", force: :cascade do |t|
    t.string "reference_id", null: false
    t.string "idempotency_key"
    t.integer "sender_id"
    t.integer "recipient_id", null: false
    t.bigint "amount_cents", null: false
    t.bigint "fee_cents", default: 0, null: false
    t.string "currency", default: "USD", null: false
    t.string "payment_type", default: "transfer", null: false
    t.string "status", default: "completed", null: false
    t.string "description"
    t.bigint "parent_payment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["idempotency_key"], name: "index_payments_on_idempotency_key", unique: true
    t.index ["recipient_id", "created_at"], name: "index_payments_on_recipient_id_and_created_at"
    t.index ["recipient_id"], name: "index_payments_on_recipient_id"
    t.index ["reference_id"], name: "index_payments_on_reference_id", unique: true
    t.index ["sender_id", "created_at"], name: "index_payments_on_sender_id_and_created_at"
    t.index ["sender_id"], name: "index_payments_on_sender_id"
    t.index ["status", "created_at"], name: "index_payments_on_status_and_created_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "payrail_tag", null: false
    t.string "password_digest", null: false
    t.string "role", default: "customer", null: false
    t.string "avatar_color", default: "#3B82F6"
    t.string "api_key"
    t.string "phone_number"
    t.boolean "kyc_verified", default: true
    t.datetime "last_sign_in_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_key"], name: "index_users_on_api_key", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["payrail_tag"], name: "index_users_on_payrail_tag", unique: true
    t.index ["role", "created_at"], name: "index_users_on_role_and_created_at"
  end

  create_table "wallets", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "wallet_number", null: false
    t.string "currency", default: "USD", null: false
    t.bigint "balance_cents", default: 0, null: false
    t.string "status", default: "active", null: false
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_wallets_on_user_id"
    t.index ["wallet_number"], name: "index_wallets_on_wallet_number", unique: true
  end

  add_foreign_key "ledger_entries", "payments"
  add_foreign_key "ledger_entries", "wallets"
  add_foreign_key "payments", "users", column: "recipient_id"
  add_foreign_key "payments", "users", column: "sender_id"
  add_foreign_key "wallets", "users"
end
