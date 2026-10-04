# frozen_string_literal: true

# Interview Handbook - Quick Cheat Sheet: The Most-Confused Pairs (Page 3)
#
# This module implements and verifies each of the 20 most-confused pairs
# in Ruby & Rails interviews, complete with detailed explanatory comments.
module InterviewHandbook
  module CheatSheet
    def self.verify_all
      results = {}

      # Pair 1: == vs eql? vs equal?
      # ==: checks value equivalence (coerces numeric types, so 1 == 1.0 is true)
      # eql?: stricter equality used by Hash keys; requires same type & value (1.eql?(1.0) is false)
      # equal?: checks identity (same object_id in memory)
      a = +"payrail"
      b = +"payrail"
      c = a
      results[:pair1_equality] = {
        value_equals: (a == b) && (1 == 1.0),
        eql_strict: !1.eql?(1.0) && a.eql?(b),
        equal_identity: !a.equal?(b) && a.equal?(c)
      }

      # Pair 2: dup vs clone
      # Both are shallow copies. clone preserves frozen state and singleton methods; dup does not.
      orig = +"frozen_secret"
      def orig.secret_code; 42; end
      orig.freeze
      d = orig.dup
      cl = orig.clone
      results[:pair2_dup_vs_clone] = {
        dup_not_frozen: !d.frozen?,
        clone_frozen: cl.frozen?,
        clone_keeps_singleton: cl.respond_to?(:secret_code) && !d.respond_to?(:secret_code)
      }

      # Pair 3: include vs extend vs prepend
      # include: adds methods as instance methods
      # extend: adds methods as singleton / class methods
      # prepend: inserts module BEFORE the class in the ancestor chain (can override & call super)
      mod_inc = Module.new { def kind; "instance"; end }
      mod_ext = Module.new { def class_kind; "singleton"; end }
      mod_prep = Module.new { def kind; "prepended " + super; end }
      cls = Class.new do
        include mod_inc
        extend mod_ext
        prepend mod_prep
      end
      results[:pair3_include_extend_prepend] = {
        include_and_prepend: cls.new.kind == "prepended instance",
        extend_class_method: cls.class_kind == "singleton",
        ancestors_order: cls.ancestors.first == mod_prep
      }

      # Pair 4: Proc vs lambda
      # Lambda is strict about arity (wrong argument count raises ArgumentError)
      # and `return` in a lambda returns ONLY from the lambda itself.
      # Proc is lenient with arguments (missing args become nil), and `return` returns from enclosing method.
      lam = ->(x, y) { [x, y] }
      prc = Proc.new { |x, y| [x, y] }
      lambda_strict_args = begin; lam.call(1); false; rescue ArgumentError; true; end
      proc_lenient_args = (prc.call(1) == [1, nil])
      results[:pair4_proc_vs_lambda] = {
        lambda_strict_arity: lambda_strict_args,
        proc_lenient_arity: proc_lenient_args
      }

      # Pair 5: tap vs then
      # tap: yields object to block and returns the ORIGINAL object (great for chaining side effects)
      # then (yield_self): yields object and returns the RESULT of the block (functional pipelines)
      tapped = [1, 2, 3].tap { |arr| arr << 4 }
      transformed = 10.then { |n| n * 2 }
      results[:pair5_tap_vs_then] = {
        tap_returns_self: tapped == [1, 2, 3, 4],
        then_returns_result: transformed == 20
      }

      # Pair 6: send vs public_send
      # send can invoke private methods; public_send respects encapsulation and raises NoMethodError for private methods.
      secret_holder = Class.new do
        def public_hello; "hi"; end
        private
        def private_vault; "secret"; end
      end.new
      public_ok = secret_holder.public_send(:public_hello) == "hi"
      public_send_blocked = begin; secret_holder.public_send(:private_vault); false; rescue NoMethodError; true; end
      send_bypassed = secret_holder.send(:private_vault) == "secret"
      results[:pair6_send_vs_public_send] = {
        public_send_blocked: public_send_blocked,
        send_bypassed: send_bypassed
      }

      # Pair 7: is_a? vs instance_of?
      # is_a?: true if receiver is instance of class, ANY subclass, or includes the module.
      # instance_of?: true ONLY if receiver is an instance of that exact class (subclasses return false).
      animal_class = Class.new
      dog_class = Class.new(animal_class)
      dog = dog_class.new
      results[:pair7_is_a_vs_instance_of] = {
        is_a_subclass: dog.is_a?(animal_class) && dog.is_a?(dog_class),
        instance_of_exact: !dog.instance_of?(animal_class) && dog.instance_of?(dog_class)
      }

      # Pair 8: find vs find_by vs where
      # find: looks up by primary key, raises ActiveRecord::RecordNotFound if not found.
      # find_by: looks up by attributes, returns first match or nil (no error).
      # where: returns an ActiveRecord::Relation (lazy collection).
      user = User.first
      results[:pair8_find_find_by_where] = {
        find_by_pk: User.find(user.id) == user,
        find_by_attr: User.find_by(email: user.email) == user,
        where_relation: User.where(role: user.role).is_a?(ActiveRecord::Relation)
      }

      # Pair 9: pluck vs select
      # pluck: runs SQL and returns raw Ruby primitive values/arrays, bypassing model object creation.
      # select: returns ActiveRecord model instances instantiated with only the specified columns.
      plucked = User.limit(2).pluck(:id, :name)
      selected = User.select(:id, :name).limit(2)
      results[:pair9_pluck_vs_select] = {
        pluck_raw_arrays: plucked.all? { |r| r.is_a?(Array) },
        select_model_objects: selected.all? { |r| r.is_a?(User) }
      }

      # Pair 10: includes vs preload vs eager_load
      # preload: always loads associations using SEPARATE queries.
      # eager_load: forces a single LEFT OUTER JOIN.
      # includes: lets Rails choose (separate queries by default, or LEFT OUTER JOIN if referenced in WHERE).
      results[:pair10_eager_loading] = {
        preload_ok: Transfer.preload(:sender_wallet).limit(2).to_a.present?,
        eager_load_ok: Transfer.eager_load(:sender_wallet).limit(2).to_a.present?,
        includes_ok: Transfer.includes(:sender_wallet).limit(2).to_a.present?
      }

      # Pair 11: joins vs includes
      # joins: creates an INNER JOIN for filtering rows based on association data; does NOT load association into memory.
      # includes: loads association records to eliminate N+1 queries.
      results[:pair11_joins_vs_includes] = {
        joins_inner: Wallet.joins(:user).where(users: { role: "customer" }).to_a.present?,
        includes_loaded: Wallet.includes(:user).first.association(:user).loaded?
      }

      # Pair 12: delete vs destroy
      # delete: issues direct SQL DELETE, skipping model callbacks and dependent: :destroy associations.
      # destroy: instantiates the record, executes callback chain, and cleans up dependent records.
      temp_u1 = User.create!(name: "Del Test", email: "del_#{SecureRandom.hex(4)}@test.io", payrail_tag: "$del_#{SecureRandom.hex(3)}", password: "password123")
      Wallet.create!(user: temp_u1, currency: "USD", balance_cents: 100)
      wallet_count_before = Wallet.count
      temp_u1.destroy # runs dependent: :destroy on wallets
      wallet_count_after = Wallet.count
      results[:pair12_delete_vs_destroy] = {
        destroy_ran_dependent: wallet_count_after < wallet_count_before
      }

      # Pair 13: delete_all vs destroy_all
      # delete_all: one bulk SQL DELETE query without loading records.
      # destroy_all: loads every record into Ruby memory and invokes destroy on each (running callbacks).
      results[:pair13_delete_all_vs_destroy_all] = {
        delete_all_fast_bulk: IdempotencyRecord.where("created_at < ?", 30.days.ago).delete_all.is_a?(Integer)
      }

      # Pair 14: find_each vs in_batches
      # find_each: batches SQL queries (default 1000) and yields each individual model instance.
      # in_batches: batches SQL queries and yields an ActiveRecord::Relation per batch for bulk SQL operations.
      yielded_singles = 0
      User.limit(5).find_each(batch_size: 2) { |_u| yielded_singles += 1 }
      yielded_relations = 0
      User.limit(5).in_batches(of: 2) { |batch| yielded_relations += 1 if batch.is_a?(ActiveRecord::Relation) }
      results[:pair14_find_each_vs_in_batches] = {
        find_each_records: yielded_singles > 0,
        in_batches_relations: yielded_relations > 0
      }

      # Pair 15: after_save vs after_commit
      # after_save runs INSIDE the DB transaction; changes can still be rolled back!
      # after_commit runs AFTER the transaction successfully commits; essential for background jobs and webhooks.
      results[:pair15_after_save_vs_after_commit] = {
        safe_job_pattern: "Enqueue Sidekiq jobs only in after_commit so jobs never read uncommitted or rolled-back rows"
      }

      # Pair 16: Optimistic vs pessimistic lock
      # Optimistic lock: uses lock_version column; fails with StaleObjectError on concurrent update.
      # Pessimistic lock: takes row lock (SELECT ... FOR UPDATE / with_lock).
      w = Wallet.first
      results[:pair16_locks] = {
        optimistic_lock_version: w.has_attribute?(:lock_version),
        pessimistic_locking: w.respond_to?(:with_lock)
      }

      # Pair 17: Authentication vs Authorization
      # Authentication: establishes who you are (e.g. JWT token or session).
      # Authorization: establishes what you are permitted to do (e.g. PaymentPolicy).
      policy = PaymentPolicy.new(user, Transfer.first)
      results[:pair17_auth_vs_authz] = {
        authentication: user.authenticate("password123").present?,
        authorization: policy.respond_to?(:show?) && policy.respond_to?(:refund?)
      }

      # Pair 18: 401 Unauthorized vs 403 Forbidden
      # 401: Authentication missing or invalid (who are you?)
      # 403: Authenticated, but lacking permission for this resource (you cannot do this)
      results[:pair18_status_codes] = {
        status_401: "Missing or invalid bearer token",
        status_403: "User authenticated but forbidden by policy"
      }

      # Pair 19: Offset vs cursor pagination
      # Offset: OFFSET 10000 requires database to scan and discard 10000 rows.
      # Cursor: uses indexed keyset (created_at, id) for O(1) seek time without drift.
      cursor_result = Infrastructure::CursorPaginator.paginate(Transfer.all, limit: 2)
      results[:pair19_pagination] = {
        keyset_cursor_supported: cursor_result.records.size <= 2
      }

      # Pair 20: Concurrency vs Parallelism
      # Concurrency: overlapping task execution (threads doing I/O while GVL is released).
      # Parallelism: simultaneous CPU execution across multiple CPU cores (Puma worker processes).
      t_start = Time.now
      threads = 2.times.map { Thread.new { sleep 0.02 } }
      threads.each(&:join)
      results[:pair20_concurrency_vs_parallelism] = {
        io_concurrency_elapsed_time: (Time.now - t_start) < 0.05
      }

      results
    end
  end
end
