class CreatePayrailCoreTables < ActiveRecord::Migration[8.1]
  def change
    # 1. Users
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false, index: { unique: true }
      t.string :payrail_tag, null: false, index: { unique: true }
      t.string :password_digest, null: false
      t.string :role, default: "customer", null: false
      t.string :avatar_color, default: "#3B82F6"
      t.string :api_key, index: { unique: true }
      t.string :phone_number
      t.boolean :kyc_verified, default: true

      t.timestamps
    end

    # 2. Wallets
    create_table :wallets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :wallet_number, null: false, index: { unique: true }
      t.string :currency, default: "USD", null: false
      t.bigint :balance_cents, default: 0, null: false
      t.string :status, default: "active", null: false
      t.bigint :daily_limit_cents, default: 1000000 # $10,000 daily limit

      t.timestamps
    end

    # 3. Virtual Cards
    create_table :virtual_cards do |t|
      t.references :user, null: false, foreign_key: true
      t.references :wallet, null: false, foreign_key: true
      t.string :card_number_last4, null: false
      t.string :card_number_full, null: false # Simulated demo card number
      t.string :cardholder_name, null: false
      t.integer :expiry_month, null: false
      t.integer :expiry_year, null: false
      t.string :cvv, null: false
      t.string :brand, default: "Visa", null: false
      t.string :tier, default: "Black Metal", null: false
      t.string :status, default: "active", null: false
      t.bigint :monthly_limit_cents, default: 500000 # $5,000 monthly
      t.bigint :spent_this_month_cents, default: 0

      t.timestamps
    end

    # 4. Transfers (Payment Transactions)
    create_table :transfers do |t|
      t.string :reference_id, null: false, index: { unique: true }
      t.bigint :sender_wallet_id, index: true
      t.bigint :recipient_wallet_id, null: false, index: true
      t.bigint :amount_cents, null: false
      t.bigint :fee_cents, default: 0, null: false
      t.string :currency, default: "USD", null: false
      t.string :transfer_type, null: false # p2p, deposit, card_purchase, payment_link, refund
      t.string :status, default: "completed", null: false # completed, pending, failed, reversed
      t.string :description
      t.string :category, default: "transfer" # transfer, dining, shopping, utilities, salary, deposit
      t.string :idempotency_key, index: true
      t.string :recipient_identifier # email or payrail_tag
      t.json :metadata

      t.timestamps
    end
    add_foreign_key :transfers, :wallets, column: :sender_wallet_id
    add_foreign_key :transfers, :wallets, column: :recipient_wallet_id

    # 5. Ledger Entries (Double-Entry Bookkeeping core)
    create_table :ledger_entries do |t|
      t.references :transfer, null: false, foreign_key: true
      t.references :wallet, null: false, foreign_key: true
      t.string :entry_type, null: false # 'debit' or 'credit'
      t.bigint :amount_cents, null: false
      t.bigint :balance_after_cents, null: false
      t.string :description, null: false

      t.timestamps
    end
    add_index :ledger_entries, [:wallet_id, :created_at]

    # 6. Payment Links (QR / Shareable Invoice links)
    create_table :payment_links do |t|
      t.references :user, null: false, foreign_key: true
      t.references :wallet, null: false, foreign_key: true
      t.string :link_token, null: false, index: { unique: true }
      t.string :title, null: false
      t.string :description
      t.bigint :amount_cents, null: false
      t.string :currency, default: "USD", null: false
      t.string :status, default: "active", null: false # active, claimed, expired
      t.string :claimed_by_name

      t.timestamps
    end

    # 7. Idempotency Records
    create_table :idempotency_records do |t|
      t.string :key, null: false, index: { unique: true }
      t.string :request_path, null: false
      t.string :request_params_hash, null: false
      t.integer :response_code, null: false
      t.text :response_body, null: false

      t.timestamps
    end

    # 8. Webhook Endpoints & Deliveries
    create_table :webhook_endpoints do |t|
      t.references :user, null: false, foreign_key: true
      t.string :url, null: false
      t.string :secret, null: false
      t.boolean :active, default: true

      t.timestamps
    end

    create_table :webhook_deliveries do |t|
      t.references :webhook_endpoint, null: false, foreign_key: true
      t.string :event_type, null: false
      t.text :payload, null: false
      t.integer :response_code
      t.string :status, default: "delivered", null: false

      t.timestamps
    end
  end
end

