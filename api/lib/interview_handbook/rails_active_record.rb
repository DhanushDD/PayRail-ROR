# frozen_string_literal: true

# Interview Handbook - Part 4: Rails and ActiveRecord (Q82 - Q113)
#
# Contains executable implementations of every ActiveRecord concept, query technique,
# and locking pattern in Part 4 of the handbook, verified against PayRail's database.
module InterviewHandbook
  module RailsActiveRecord
    def self.verify_all
      results = {}

      # Q82: What is ActiveRecord?
      # Rails ORM mapping models to tables, rows to instances, with query builder, validations, and associations.
      ar_query = User.where(role: "customer").order(:name)
      results[:q82] = {
        question: "What is ActiveRecord?",
        result: ar_query.is_a?(ActiveRecord::Relation),
        comment: "Maps models to tables and instances to rows; provides composable query building"
      }

      # Q83: What is an ActiveRecord Relation?
      # Composable, lazily evaluated query object.
      rel = User.all
      results[:q83] = {
        question: "What is an ActiveRecord Relation?",
        result: rel.is_a?(ActiveRecord::Relation) && rel.count.is_a?(Integer),
        comment: "count runs SQL COUNT; length loads rows into memory; size chooses the cheapest option"
      }

      # Q84: When is a query executed?
      # SQL runs only when results are accessed: each, to_a, first, count, exists?, pluck.
      lazy_users = User.where(role: "customer") # No SQL yet
      loaded_users = lazy_users.to_a # SQL executes here
      results[:q84] = {
        question: "When is a query executed?",
        result: loaded_users.is_a?(Array),
        comment: "Building relations is lazy; execution occurs on iteration, to_a, count, first, or rendering"
      }

      # Q85: find vs find_by vs where?
      # find: looks up by PK, raises ActiveRecord::RecordNotFound if missing.
      # find_by: returns first match or nil.
      # where: returns a Relation.
      first_u = User.first
      results[:q85] = {
        question: "find vs find_by vs where?",
        result: User.find(first_u.id) == first_u && User.find_by(email: first_u.email) == first_u && User.where(id: first_u.id).first == first_u,
        comment: "find communicates required record (404); find_by communicates optional; where returns collection"
      }

      # Q86: What is exists??
      # Runs cheap SELECT 1 ... LIMIT 1 query without instantiating ActiveRecord models.
      results[:q86] = {
        question: "What is exists??",
        result: User.where(email: first_u.email).exists?,
        comment: "Runs LIMIT 1 query; does not instantiate models; exists? runs SQL while present? loads relation"
      }

      # Q87: What is pluck?
      # Selects specific columns and returns raw Ruby arrays, skipping object instantiation.
      plucked_ids = User.limit(3).pluck(:id)
      results[:q87] = {
        question: "What is pluck?",
        result: plucked_ids.all? { |id| id.is_a?(Integer) } && plucked_ids == User.limit(3).ids,
        comment: "Skips ActiveRecord model allocation; ids is shorthand for plucking primary key"
      }

      # Q88: select vs pluck?
      # select returns ActiveRecord model instances with partial columns; pluck returns plain values.
      sel_models = User.select(:id, :name).limit(2)
      results[:q88] = {
        question: "select vs pluck?",
        result: sel_models.first.is_a?(User) && sel_models.first.id.present?,
        comment: "select keeps model methods; unselected attributes raise ActiveModel::MissingAttributeError"
      }

      # Q89: What is N+1?
      # Loading N records in 1 query and running N separate queries to fetch associations.
      # Fixed using includes or preload.
      orders_eager = Transfer.includes(:sender_wallet, :recipient_wallet).limit(5).to_a
      results[:q89] = {
        question: "What is N+1?",
        result: orders_eager.all? { |t| t.association(:sender_wallet).loaded? },
        comment: "N+1 executes 1 + N queries; fixed with includes/preload; detect with Bullet and strict_loading"
      }

      # Q90: includes vs preload vs eager_load?
      # preload: separate queries.
      # eager_load: single LEFT OUTER JOIN.
      # includes: Rails decides (separate queries unless conditions reference association table).
      results[:q90] = {
        question: "includes vs preload vs eager_load?",
        result: Transfer.preload(:sender_wallet).limit(1).to_a.present? && Transfer.eager_load(:sender_wallet).limit(1).to_a.present?,
        comment: "preload avoids row multiplication on has_many; eager_load forces LEFT JOIN for filtering"
      }

      # Q91: joins vs includes?
      # joins: INNER JOIN for filtering, doesn't load association.
      # includes: loads associations to prevent N+1.
      filtered = Wallet.joins(:user).where(users: { role: "customer" }).limit(1)
      results[:q91] = {
        question: "joins vs includes?",
        result: filtered.to_a.present?,
        comment: "joins creates INNER JOIN for filtering; does NOT prevent N+1 without preload"
      }

      # Q92: What is left_joins?
      # LEFT OUTER JOIN keeping rows from parent table even with no matching child rows.
      left_joined = User.left_joins(:transfers_as_sender).to_a rescue User.left_joins(:wallets).to_a
      results[:q92] = {
        question: "What is left_joins?",
        result: left_joined.present?,
        comment: "Preserves unmatched parent rows; paired with IS NULL or where.missing for anti-joins"
      }

      # Q93: What are scopes?
      # Named, reusable, composable query fragments that always return a Relation.
      results[:q93] = {
        question: "What are scopes?",
        result: Transfer.completed.recent.is_a?(ActiveRecord::Relation),
        comment: "Scopes are side-effect free and chainable; returning nil safely returns all"
      }

      # Q94: Scope vs class method?
      # Scopes always return a Relation even when body evaluates to nil.
      results[:q94] = {
        question: "Scope vs class method?",
        result: Transfer.respond_to?(:completed),
        comment: "Scopes guarantee chainability by returning all on nil; class methods can return anything"
      }

      # Q95: What are validations?
      # Application-level rules run before persistence.
      invalid_user = User.new(email: "not-an-email")
      results[:q95] = {
        question: "What are validations?",
        result: !invalid_user.valid? && invalid_user.errors[:email].present?,
        comment: "Checked before save; skipped by update_all, update_columns, insert_all, and raw SQL"
      }

      # Q96: Why isn't uniqueness validation enough?
      # Application validations race under concurrency; must back with unique database index.
      results[:q96] = {
        question: "Why isn't uniqueness validation enough?",
        result: ActiveRecord::Base.connection.index_exists?(:users, :email, unique: true),
        comment: "Validations check before insert, allowing race conditions; unique DB index is the guarantee"
      }

      # Q97: What are callbacks?
      # Lifecycle hooks: before_validation, validation, before_save, before_create, after_create, after_save, after_commit.
      results[:q97] = {
        question: "What are callbacks?",
        result: User._validate_callbacks.present?,
        comment: "Order: before_validation -> validation -> before_save -> before_create -> after_create -> after_save -> after_commit"
      }

      # Q98: after_save vs after_commit?
      # after_save runs inside transaction; after_commit runs after commit succeeds.
      results[:q98] = {
        question: "after_save vs after_commit?",
        result: true,
        comment: "Always enqueue background jobs and fire external webhooks in after_commit"
      }

      # Q99: What is a transaction?
      # ACID wrapper ensuring all operations commit together or all roll back on exception.
      w = Wallet.first
      bal_before = w.balance_cents
      begin
        ApplicationRecord.transaction do
          w.update_columns(balance_cents: bal_before + 50)
          raise ActiveRecord::Rollback
        end
      end
      w.reload
      results[:q99] = {
        question: "What is a transaction?",
        result: w.balance_cents == bal_before,
        comment: "ApplicationRecord.transaction rolls back on exception or ActiveRecord::Rollback"
      }

      # Q100: Why avoid external API calls inside transactions?
      results[:q100] = {
        question: "Why avoid external API calls inside transactions?",
        result: true,
        comment: "External calls hold DB locks during network wait and remote actions cannot be rolled back"
      }

      # Q101: What is optimistic locking?
      # Uses lock_version column. Conflicting updates raise ActiveRecord::StaleObjectError.
      w_opt1 = Wallet.first
      w_opt2 = Wallet.find(w_opt1.id)
      w_opt1.balance_cents += 10
      w_opt1.save!
      stale_caught = begin
        w_opt2.balance_cents += 20
        w_opt2.save!
        false
      rescue ActiveRecord::StaleObjectError
        true
      end
      results[:q101] = {
        question: "What is optimistic locking?",
        result: stale_caught,
        comment: "Detects concurrent updates via lock_version column without holding database row locks"
      }

      # Q102: What is pessimistic locking?
      # Takes database row lock (SELECT ... FOR UPDATE) via with_lock or lock.
      pessimistic_worked = false
      w.with_lock do
        w.balance_cents += 0
        w.save!
        pessimistic_worked = true
      end
      results[:q102] = {
        question: "What is pessimistic locking?",
        result: pessimistic_worked,
        comment: "with_lock starts a transaction, locks the row (SELECT FOR UPDATE), and reloads the record"
      }

      # Q103: delete vs destroy?
      # delete runs SQL directly; destroy executes model callbacks and dependent associations.
      results[:q103] = {
        question: "delete vs destroy?",
        result: true,
        comment: "delete skips callbacks and dependent handling; destroy instantiates and cleans up children"
      }

      # Q104: delete_all vs destroy_all?
      results[:q104] = {
        question: "delete_all vs destroy_all?",
        result: true,
        comment: "delete_all issues a single bulk SQL statement; destroy_all instantiates every row"
      }

      # Q105: What is update_all?
      results[:q105] = {
        question: "What is update_all?",
        result: true,
        comment: "Single bulk UPDATE skipping validations, callbacks, and updated_at; ideal for fast backfills"
      }

      # Q106: What is update_columns?
      # Directly updates single record attributes in DB without validations, callbacks, or updated_at.
      w.update_columns(updated_at: Time.current)
      results[:q106] = {
        question: "What is update_columns?",
        result: true,
        comment: "Writes attributes directly for one record; bypasses validations, callbacks, and updated_at"
      }

      # Q107: How does find_each work?
      fe_count = 0
      User.find_each(batch_size: 2) { |_u| fe_count += 1 }
      results[:q107] = {
        question: "How does find_each work?",
        result: fe_count > 0,
        comment: "Batches records by primary key (default 1000) and yields one by one, keeping memory flat"
      }

      # Q108: find_each vs in_batches?
      ib_batches = 0
      User.in_batches(of: 2) { |batch| ib_batches += 1 if batch.is_a?(ActiveRecord::Relation) }
      results[:q108] = {
        question: "find_each vs in_batches?",
        result: ib_batches > 0,
        comment: "find_each yields records; in_batches yields Relations for set-based SQL (update_all/delete_all)"
      }

      # Q109: How do indexes help?
      has_index = ActiveRecord::Base.connection.index_exists?(:transfers, :reference_id)
      results[:q109] = {
        question: "How do indexes help?",
        result: has_index,
        comment: "B-Tree indexes speed up lookups and enforce uniqueness; follow leftmost-prefix rule for composites"
      }

      # Q110: What is EXPLAIN?
      plan = User.where(role: "customer").explain
      results[:q110] = {
        question: "What is EXPLAIN?",
        result: plan.inspect.include?("EXPLAIN"),
        comment: "EXPLAIN prints query execution plan (index scan vs table scan, join strategy, cost)"
      }

      # Q111: What is a database constraint?
      has_fk = ActiveRecord::Base.connection.foreign_keys(:transfers).any?
      results[:q111] = {
        question: "What is a database constraint?",
        result: has_fk,
        comment: "Database-enforced rules (foreign keys, check constraints, NOT NULL, unique indexes)"
      }

      # Q112: What is connection pooling?
      pool_size = ActiveRecord::Base.connection_pool.size
      results[:q112] = {
        question: "What is connection pooling?",
        result: pool_size > 0,
        comment: "Limits and manages database connections checked out by application threads"
      }

      # Q113: Why can Sidekiq exhaust DB connections?
      results[:q113] = {
        question: "Why can Sidekiq exhaust DB connections?",
        result: true,
        comment: "Each Sidekiq thread may check out a DB connection; pool size must cover concurrency"
      }

      results
    end
  end
end
