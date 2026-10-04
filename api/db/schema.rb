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

ActiveRecord::Schema[8.1].define(version: 2026_10_04_090600) do
  create_table "email_deliveries", force: :cascade do |t|
    t.integer "user_id"
    t.string "recipient_email", null: false
    t.string "subject", null: false
    t.string "idempotency_key", null: false
    t.string "provider_message_id"
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["idempotency_key"], name: "index_email_deliveries_on_idempotency_key", unique: true
    t.index ["status", "created_at"], name: "index_email_deliveries_on_status_and_created_at"
    t.index ["user_id"], name: "index_email_deliveries_on_user_id"
  end

  create_table "idempotency_records", force: :cascade do |t|
    t.string "key", null: false
    t.string "request_path", null: false
    t.string "request_params_hash", null: false
    t.integer "response_code", null: false
    t.text "response_body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_idempotency_records_on_key", unique: true
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.integer "transfer_id", null: false
    t.integer "wallet_id", null: false
    t.string "entry_type", null: false
    t.bigint "amount_cents", null: false
    t.bigint "balance_after_cents", null: false
    t.string "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["transfer_id"], name: "index_ledger_entries_on_transfer_id"
    t.index ["wallet_id", "created_at"], name: "index_ledger_entries_on_wallet_id_and_created_at"
    t.index ["wallet_id"], name: "index_ledger_entries_on_wallet_id"
  end

  create_table "outbox_events", force: :cascade do |t|
    t.string "event_type", null: false
    t.string "aggregate_type", null: false
    t.string "aggregate_id", null: false
    t.json "payload", null: false
    t.string "status", default: "pending", null: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status", "created_at"], name: "index_outbox_events_on_status_and_created_at"
  end

  create_table "payment_links", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "wallet_id", null: false
    t.string "link_token", null: false
    t.string "title", null: false
    t.string "description"
    t.bigint "amount_cents", null: false
    t.string "currency", default: "USD", null: false
    t.string "status", default: "active", null: false
    t.string "claimed_by_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["link_token"], name: "index_payment_links_on_link_token", unique: true
    t.index ["user_id"], name: "index_payment_links_on_user_id"
    t.index ["wallet_id"], name: "index_payment_links_on_wallet_id"
  end

  create_table "sms_campaigns", force: :cascade do |t|
    t.string "title", null: false
    t.string "status", default: "draft", null: false
    t.text "message", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sms_recipients", force: :cascade do |t|
    t.integer "sms_campaign_id", null: false
    t.string "phone_number", null: false
    t.string "status", default: "pending", null: false
    t.string "provider_message_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sms_campaign_id", "status"], name: "index_sms_recipients_on_sms_campaign_id_and_status"
    t.index ["sms_campaign_id"], name: "index_sms_recipients_on_sms_campaign_id"
  end

  create_table "transfers", force: :cascade do |t|
    t.string "reference_id", null: false
    t.bigint "sender_wallet_id"
    t.bigint "recipient_wallet_id", null: false
    t.bigint "amount_cents", null: false
    t.bigint "fee_cents", default: 0, null: false
    t.string "currency", default: "USD", null: false
    t.string "transfer_type", null: false
    t.string "status", default: "completed", null: false
    t.string "description"
    t.string "category", default: "transfer"
    t.string "idempotency_key"
    t.string "recipient_identifier"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["idempotency_key"], name: "index_transfers_on_idempotency_key"
    t.index ["recipient_wallet_id"], name: "index_transfers_on_recipient_wallet_id"
    t.index ["reference_id"], name: "index_transfers_on_reference_id", unique: true
    t.index ["sender_wallet_id"], name: "index_transfers_on_sender_wallet_id"
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_key"], name: "index_users_on_api_key", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["payrail_tag"], name: "index_users_on_payrail_tag", unique: true
  end

  create_table "virtual_cards", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "wallet_id", null: false
    t.string "card_number_last4", null: false
    t.string "card_number_full", null: false
    t.string "cardholder_name", null: false
    t.integer "expiry_month", null: false
    t.integer "expiry_year", null: false
    t.string "cvv", null: false
    t.string "brand", default: "Visa", null: false
    t.string "tier", default: "Black Metal", null: false
    t.string "status", default: "active", null: false
    t.bigint "monthly_limit_cents", default: 500000
    t.bigint "spent_this_month_cents", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_virtual_cards_on_user_id"
    t.index ["wallet_id"], name: "index_virtual_cards_on_wallet_id"
  end

  create_table "wallets", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "wallet_number", null: false
    t.string "currency", default: "USD", null: false
    t.bigint "balance_cents", default: 0, null: false
    t.string "status", default: "active", null: false
    t.bigint "daily_limit_cents", default: 1000000
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "lock_version", default: 0, null: false
    t.index ["user_id"], name: "index_wallets_on_user_id"
    t.index ["wallet_number"], name: "index_wallets_on_wallet_number", unique: true
  end

  create_table "webhook_deliveries", force: :cascade do |t|
    t.integer "webhook_endpoint_id", null: false
    t.string "event_type", null: false
    t.text "payload", null: false
    t.integer "response_code"
    t.string "status", default: "delivered", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["webhook_endpoint_id"], name: "index_webhook_deliveries_on_webhook_endpoint_id"
  end

  create_table "webhook_endpoints", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "url", null: false
    t.string "secret", null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_webhook_endpoints_on_user_id"
  end

  add_foreign_key "email_deliveries", "users"
  add_foreign_key "ledger_entries", "transfers"
  add_foreign_key "ledger_entries", "wallets"
  add_foreign_key "payment_links", "users"
  add_foreign_key "payment_links", "wallets"
  add_foreign_key "sms_recipients", "sms_campaigns"
  add_foreign_key "transfers", "wallets", column: "recipient_wallet_id"
  add_foreign_key "transfers", "wallets", column: "sender_wallet_id"
  add_foreign_key "virtual_cards", "users"
  add_foreign_key "virtual_cards", "wallets"
  add_foreign_key "wallets", "users"
  add_foreign_key "webhook_deliveries", "webhook_endpoints"
  add_foreign_key "webhook_endpoints", "users"
end
