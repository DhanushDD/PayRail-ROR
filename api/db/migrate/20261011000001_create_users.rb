class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :payrail_tag, null: false
      t.string :password_digest, null: false
      t.string :role, default: "customer", null: false
      t.string :avatar_color, default: "#3B82F6"
      t.string :api_key
      t.string :phone_number
      t.boolean :kyc_verified, default: true
      t.datetime :last_sign_in_at
      t.integer :sign_in_count, default: 0, null: false

      t.timestamps
    end

    # Database performance optimization using unique & composite indexing
    add_index :users, :email, unique: true
    add_index :users, :payrail_tag, unique: true
    add_index :users, :api_key, unique: true
    add_index :users, [:role, :created_at]

    create_table :wallets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :wallet_number, null: false
      t.string :currency, default: "USD", null: false
      t.bigint :balance_cents, default: 0, null: false
      t.string :status, default: "active", null: false
      t.integer :lock_version, default: 0, null: false

      t.timestamps
    end

    add_index :wallets, :wallet_number, unique: true

    create_table :payments do |t|
      t.string :reference_id, null: false
      t.string :idempotency_key
      t.references :sender, foreign_key: { to_table: :users }
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.bigint :amount_cents, null: false
      t.bigint :fee_cents, default: 0, null: false
      t.string :currency, default: "USD", null: false
      t.string :payment_type, default: "transfer", null: false # "transfer", "deposit", "refund"
      t.string :status, default: "completed", null: false      # "pending", "completed", "refunded", "failed"
      t.string :description
      t.bigint :parent_payment_id

      t.timestamps
    end

    add_index :payments, :reference_id, unique: true
    add_index :payments, :idempotency_key, unique: true
    add_index :payments, [:sender_id, :created_at]
    add_index :payments, [:recipient_id, :created_at]
    add_index :payments, [:status, :created_at]

    create_table :ledger_entries do |t|
      t.references :payment, null: false, foreign_key: true
      t.references :wallet, null: false, foreign_key: true
      t.string :entry_type, null: false # "debit" or "credit"
      t.bigint :amount_cents, null: false
      t.bigint :balance_after_cents, null: false
      t.string :description, null: false

      t.timestamps
    end

    add_index :ledger_entries, [:wallet_id, :created_at]
  end
end
