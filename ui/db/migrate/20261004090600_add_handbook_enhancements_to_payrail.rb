# Migration to add schema enhancements supporting patterns from Ruby & Rails Interview Handbook:
# - lock_version on wallets for Optimistic Locking (Q101)
# - outbox_events table for Outbox Pattern transactional publishing (Q124)
# - email_deliveries table with unique idempotency_key for Email System (Q149)
# - sms_campaigns & sms_recipients for SMS Campaign Architecture (Q150)
class AddHandbookEnhancementsToPayrail < ActiveRecord::Migration[8.1]
  def change
    # 1. Optimistic Locking support (Q101)
    add_column :wallets, :lock_version, :integer, default: 0, null: false

    # 2. Outbox Pattern for guaranteed at-least-once message dispatching (Q124)
    create_table :outbox_events do |t|
      t.string :event_type, null: false
      t.string :aggregate_type, null: false
      t.string :aggregate_id, null: false
      t.json :payload, null: false
      t.string :status, default: "pending", null: false
      t.datetime :published_at
      t.timestamps

      t.index [:status, :created_at]
    end

    # 3. Email Delivery with Idempotency Key (Q149)
    create_table :email_deliveries do |t|
      t.references :user, foreign_key: true
      t.string :recipient_email, null: false
      t.string :subject, null: false
      t.string :idempotency_key, null: false
      t.string :provider_message_id
      t.string :status, default: "pending", null: false
      t.timestamps

      t.index :idempotency_key, unique: true
      t.index [:status, :created_at]
    end

    # 4. SMS Campaigns with batch processing and safe pause/resume states (Q150)
    create_table :sms_campaigns do |t|
      t.string :title, null: false
      t.string :status, default: "draft", null: false # draft, running, paused, completed
      t.text :message, null: false
      t.timestamps
    end

    create_table :sms_recipients do |t|
      t.references :sms_campaign, null: false, foreign_key: true
      t.string :phone_number, null: false
      t.string :status, default: "pending", null: false # pending, sent, failed
      t.string :provider_message_id
      t.timestamps

      t.index [:sms_campaign_id, :status]
    end
  end
end
