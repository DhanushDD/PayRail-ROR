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
  end
end
