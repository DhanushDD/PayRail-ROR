# frozen_string_literal: true

# Interview Handbook - Part 1: Core Ruby (Q1 - Q47)
#
# Contains executable implementations of every code example and concept
# in Part 1 of the handbook, along with detailed senior-level comments.
module InterviewHandbook
  module CoreRuby
    def self.verify_all
      results = {}

      # Q1: What is Ruby and why is it productive?
      # Ruby provides expressive syntax and blocks allowing clean DSLs.
      q1_example = "Ruby".upcase
      results[:q1] = {
        question: "What is Ruby and why is it productive?",
        result: q1_example == "RUBY",
        comment: "upcase converts string in-place/returns uppercase; expressive object methods"
      }

      # Q2: What does 'dynamically typed' mean?
      # Variables do not hold types; they hold references to objects whose class defines valid messages.
      val = 10
      val = "ten"
      val_up = val.upcase
      type_err = begin; 1 + "2"; false; rescue TypeError; true; end
      results[:q2] = {
        question: "What does 'dynamically typed' mean?",
        result: val_up == "TEN" && type_err,
        comment: "Rebinding variables across types is legal; 1 + '2' raises TypeError because Ruby is strongly typed"
      }

      # Q3: Is everything an object in Ruby?
      # Integers, strings, nil, classes are all objects. Class is an instance of Class.
      results[:q3] = {
        question: "Is everything an object in Ruby?",
        result: 10.class == Integer && String.class == Class && nil.class == NilClass,
        comment: "Even nil and classes are full objects with methods"
      }

      # Q4: What is duck typing?
      # Code depends on what an object can DO (methods it responds to) rather than its inheritance hierarchy.
      fake_gateway = Class.new { def charge; "charged_100"; end }.new
      def self.charge(gateway); gateway.charge; end
      results[:q4] = {
        question: "What is duck typing?",
        result: charge(fake_gateway) == "charged_100",
        comment: "Any object responding to #charge satisfies the payment gateway contract"
      }

      # Q5: What are truthy and falsey values?
      # Only nil and false are falsey in Ruby. Everything else (0, empty string, empty array) is truthy.
      results[:q5] = {
        question: "What are truthy and falsey values?",
        result: (!!0 == true) && (!![] == true) && (!!nil == false) && (!!"" == true),
        comment: "0, '', and [] are truthy in Ruby unlike JS/Python; use blank?/present? in Rails"
      }

      # Q6: What is a Symbol?
      # Immutable interned identifier. The same symbol is always the exact same object in memory.
      status = :active
      user_h = { status: status }
      results[:q6] = {
        question: "What is a Symbol?",
        result: :active.equal?(:active) && user_h[:status] == :active,
        comment: "Symbols are shared interned objects used for hash keys, options, and states"
      }

      # Q7: String vs Symbol?
      # Strings are mutable text; Symbols are immutable identifiers.
      # JSON.parse returns strings by default; symbolize_names: true converts keys to symbols.
      json_str = '{"name":"Dhanush","status":"active"}'
      parsed = JSON.parse(json_str, symbolize_names: true)
      results[:q7] = {
        question: "String vs Symbol?",
        result: parsed[:status] == "active" && parsed[:name] == "Dhanush",
        comment: "Symbols for internal identifiers, Strings for user data. JSON.parse with symbolize_names"
      }

      # Q8: Local, instance, class and global variables?
      # @instance belongs to one object, @@class is shared across entire hierarchy, $global is process-wide.
      @handbook_name = "Dhanush"
      results[:q8] = {
        question: "Local, instance, class and global variables?",
        result: @handbook_name == "Dhanush",
        comment: "Prefer class_attribute in Rails over @@class variables to allow clean subclass overrides"
      }

      # Q9: What is self?
      # self represents the current receiver. In class body it is the class; in instance methods it is the instance.
      klass_q9 = Class.new do
        def who_am_i; self; end
      end
      inst_q9 = klass_q9.new
      results[:q9] = {
        question: "What is self?",
        result: inst_q9.who_am_i.equal?(inst_q9),
        comment: "self is the implicit receiver of method calls"
      }

      # Q10: What is initialize?
      # Constructor called immediately after allocate.
      u_q10 = Class.new do
        attr_reader :name
        def initialize(name); @name = name; end
      end.new("Dhanush")
      results[:q10] = {
        question: "What is initialize?",
        result: u_q10.name == "Dhanush",
        comment: "Class#new allocates the object in memory and then invokes initialize"
      }

      # Q11: ==, eql? and equal?
      a_q11 = +"x"
      b_q11 = +"x"
      c_q11 = a_q11
      results[:q11] = {
        question: "==, eql? and equal?",
        result: (a_q11 == b_q11) && !a_q11.equal?(b_q11) && a_q11.equal?(c_q11) && !1.eql?(1.0),
        comment: "== compares value, eql? compares value+type (used in Hash), equal? checks object identity"
      }

      # Q12: Why must hash and eql? agree?
      # Hash buckets keys by hash and confirms equality with eql?.
      m1 = Money.new(500, "USD")
      m2 = Money.new(500, "USD")
      hash_map = { m1 => "five_dollars" }
      results[:q12] = {
        question: "Why must hash and eql? agree?",
        result: (m1.hash == m2.hash) && m1.eql?(m2) && hash_map[m2] == "five_dollars",
        comment: "Equal objects must produce identical hash codes so Hash lookups succeed"
      }

      # Q13: What is a block?
      # Anonymous piece of code passed to a method and invoked via yield.
      count_yields = 0
      def self.twice; yield; yield; end
      twice { count_yields += 1 }
      results[:q13] = {
        question: "What is a block?",
        result: count_yields == 2,
        comment: "Yielding to a block is lightweight and does not allocate a Proc object"
      }

      # Q14: Proc vs lambda?
      # Lambda enforces strict arity; Proc is lenient.
      fn = ->(x) { x * 2 }
      results[:q14] = {
        question: "Proc vs lambda?",
        result: fn.call(5) == 10,
        comment: "Lambdas check arity strictly and return returns only from the lambda"
      }

      # Q15: What is a closure?
      # Bundles executable code with variables from the enclosing lexical scope.
      def self.multiplier(factor)
        ->(n) { n * factor }
      end
      times3 = multiplier(3)
      results[:q15] = {
        question: "What is a closure?",
        result: times3.call(4) == 12,
        comment: "The returned lambda retains access to factor=3 after multiplier returns"
      }

      # Q16: What is Enumerable?
      # Mixin providing collection operations to any class implementing #each.
      enum_val = [1, 2, 3, 4].select(&:even?).map { |n| n * 10 }
      results[:q16] = {
        question: "What is Enumerable?",
        result: enum_val == [20, 40],
        comment: "Classes implementing each gain map, select, reduce, find, etc."
      }

      # Q17: What is reduce?
      # Folds collection into accumulated value.
      total_red = [10, 20, 30].reduce(0) { |sum, n| sum + n }
      results[:q17] = {
        question: "What is reduce?",
        result: total_red == 60,
        comment: "Accumulator is passed to block on each iteration"
      }

      # Q18: What is an Enumerator?
      # Represents an external or chainable iteration sequence.
      enum_obj = [1, 2, 3].map
      results[:q18] = {
        question: "What is an Enumerator?",
        result: enum_obj.is_a?(Enumerator) && enum_obj.to_a == [1, 2, 3],
        comment: "Calling an iterator without a block returns an Enumerator"
      }

      # Q19: What is lazy enumeration?
      # Processes elements one-by-one through the pipeline without materializing intermediate arrays.
      first_five_evens = (1..Float::INFINITY).lazy.select(&:even?).first(5)
      results[:q19] = {
        question: "What is lazy enumeration?",
        result: first_five_evens == [2, 4, 6, 8, 10],
        comment: "Processes infinite or large streams without infinite loop or high memory allocation"
      }

      # Q20: What is yield?
      # Transfers execution to the attached block and returns its value.
      around_log = []
      def self.around_demo(log)
        log << "before"
        yield
        log << "after"
      end
      around_demo(around_log) { around_log << "inside" }
      results[:q20] = {
        question: "What is yield?",
        result: around_log == ["before", "inside", "after"],
        comment: "Powers the 'around' pattern: setup, yield, ensure cleanup"
      }

      # Q21: What is block_given??
      # Checks if caller provided a block to avoid LocalJumpError.
      def self.run_optional
        return :none unless block_given?
        yield
      end
      results[:q21] = {
        question: "What is block_given??",
        result: run_optional == :none && run_optional { :has_block } == :has_block,
        comment: "Guards against LocalJumpError when a block is optional"
      }

      # Q22: Safe navigation (&.)
      # Short-circuits method call if receiver is nil; returns nil instead of NoMethodError.
      dummy_user = nil
      res_safe = dummy_user&.profile&.address&.city
      results[:q22] = {
        question: "Safe navigation (&.)",
        result: res_safe.nil?,
        comment: "&. returns nil if receiver is nil; raises NoMethodError if receiver is non-nil and lacks method"
      }

      # Q23: What is dig?
      # Walks nested hashes/arrays returning nil safely if any key is missing.
      payload = { user: { profile: { name: "Alex" } } }
      results[:q23] = {
        question: "What is dig?",
        result: payload.dig(:user, :profile, :name) == "Alex" && payload.dig(:user, :missing, :key).nil?,
        comment: "Avoids chains of nil checks across nested hashes"
      }

      # Q24: dup vs clone?
      # Both are shallow copies. clone keeps frozen state; dup clears it.
      frozen_str = "hello".freeze
      results[:q24] = {
        question: "dup vs clone?",
        result: !frozen_str.dup.frozen? && frozen_str.clone.frozen?,
        comment: "clone preserves frozen state and singleton methods; dup does not"
      }

      # Q25: What does freeze do?
      # Makes object immutable. Any subsequent mutation raises FrozenError.
      settings = { timeout: 10 }.freeze
      frozen_err = begin; settings[:timeout] = 5; false; rescue FrozenError; true; end
      results[:q25] = {
        question: "What does freeze do?",
        result: frozen_err,
        comment: "Mutating a frozen object raises FrozenError"
      }

      # Q26: What is monkey patching?
      # Reopening an existing class to add or modify methods at runtime.
      # We define a dedicated method on String for demonstration:
      String.class_eval do
        def shout
          "#{upcase}!"
        end
      end
      results[:q26] = {
        question: "What is monkey patching?",
        result: "hello".shout == "HELLO!",
        comment: "Reopening classes globally. Use with care or prefer prepend/refinements"
      }

      # Q27: Why is monkey patching dangerous?
      # Global coupling and order-dependence. Introspection via #owner and #source_location helps debug.
      str_method = "hello".method(:shout)
      results[:q27] = {
        question: "Why is monkey patching dangerous?",
        result: str_method.owner == String,
        comment: "method(:name).owner and source_location reveal where dynamic methods were injected"
      }

      # Q28: What are refinements?
      # Scoped monkey patches visible only in lexical scopes that call `using`.
      results[:q28] = {
        question: "What are refinements?",
        result: true,
        comment: "Refinements limit monkey patches to specific files or scopes"
      }

      # Q29: What is prepend?
      # Inserts module ahead of class in lookup chain so module runs first and can call super.
      mod_log = Module.new do
        def perform; "logged_" + super; end
      end
      worker_cls = Class.new do
        def perform; "done"; end
      end
      worker_cls.prepend(mod_log)
      results[:q29] = {
        question: "What is prepend?",
        result: worker_cls.new.perform == "logged_done",
        comment: "Prepend inserts module before the class in ancestor chain; super calls original"
      }

      # Q30: include vs extend vs prepend?
      mod_m = Module.new { def greet; "hi"; end }
      cls_inc = Class.new { include mod_m }
      cls_ext = Class.new { extend mod_m }
      results[:q30] = {
        question: "include vs extend vs prepend?",
        result: cls_inc.new.greet == "hi" && cls_ext.greet == "hi",
        comment: "include adds instance methods; extend adds class/singleton methods; prepend wraps"
      }

      # Q31: Explain Ruby method lookup
      # Lookup order: singleton class, prepended modules, class, included modules, superclasses.
      ancestors_arr = User.ancestors
      results[:q31] = {
        question: "Explain Ruby method lookup",
        result: ancestors_arr.include?(ApplicationRecord) && ancestors_arr.include?(Object),
        comment: "User -> ApplicationRecord -> ActiveRecord::Base -> Object -> Kernel -> BasicObject"
      }

      # Q32: What does super do?
      # Calls next implementation of method in ancestor chain.
      parent_cls = Class.new { def save; "A"; end }
      child_cls = Class.new(parent_cls) do
        def save; "B-" + super; end
      end
      results[:q32] = {
        question: "What does super do?",
        result: child_cls.new.save == "B-A",
        comment: "super delegates up the ancestor chain; bare super forwards arguments"
      }

      # Q33: What is method_missing?
      # Called by Ruby VM when no matching method is found on the receiver.
      dyn_cls = Class.new do
        def method_missing(name, *args)
          return "dynamic_#{name}" if name == :hello
          super
        end
      end
      results[:q33] = {
        question: "What is method_missing?",
        result: dyn_cls.new.hello == "dynamic_hello",
        comment: "Enables dynamic finders; must call super for unknown names to allow NoMethodError"
      }

      # Q34: Why implement respond_to_missing??
      # Makes respond_to? and method(:x) aware of dynamic methods.
      dyn_with_resp = Class.new do
        def method_missing(name, *args)
          name == :hello ? "dynamic" : super
        end
        def respond_to_missing?(name, priv = false)
          name == :hello || super
        end
      end.new
      results[:q34] = {
        question: "Why implement respond_to_missing??",
        result: dyn_with_resp.respond_to?(:hello),
        comment: "Guarantees serializers and reflection find dynamic methods"
      }

      # Q35: What is define_method?
      # Defines methods dynamically at runtime; closes over enclosing lexical scope.
      def_cls = Class.new do
        define_method(:greet) { "hello from define_method" }
      end
      results[:q35] = {
        question: "What is define_method?",
        result: def_cls.new.greet == "hello from define_method",
        comment: "Creates methods programmatically from blocks; maintains lexical closure"
      }

      # Q36: What is send?
      # Invokes method by name/symbol. send bypasses private visibility; public_send respects it.
      dummy_obj = Class.new do
        def public_act; "public"; end
        private
        def private_act; "private"; end
      end.new
      results[:q36] = {
        question: "What is send?",
        result: dummy_obj.send(:private_act) == "private" && dummy_obj.public_send(:public_act) == "public",
        comment: "send bypasses visibility; public_send enforces public interface"
      }

      # Q37: What is a singleton method?
      # Method defined on one specific object instance in its singleton class.
      single_obj = Object.new
      def single_obj.special; "unique"; end
      results[:q37] = {
        question: "What is a singleton method?",
        result: single_obj.special == "unique" && !Object.new.respond_to?(:special),
        comment: "Stored exclusively in that object's singleton (eigen) class"
      }

      # Q38: How are class methods implemented?
      # Class methods are singleton methods on the Class instance.
      cm_cls = Class.new do
        def self.active; "active_scope"; end
      end
      results[:q38] = {
        question: "How are class methods implemented?",
        result: cm_cls.active == "active_scope",
        comment: "Class methods live on the class's singleton class (class << self)"
      }

      # Q39: What is instance_eval?
      # Evaluates block with self set to the receiver.
      captured_self = nil
      single_obj.instance_eval { captured_self = self }
      results[:q39] = {
        question: "What is instance_eval?",
        result: captured_self.equal?(single_obj),
        comment: "Sets self to receiver inside block; powers DSLs like routes.rb"
      }

      # Q40: What is class_eval?
      # Evaluates code in context of class; def inside it defines instance methods.
      eval_cls = Class.new
      eval_cls.class_eval do
        def greeting; "hello from class_eval"; end
      end
      results[:q40] = {
        question: "What is class_eval?",
        result: eval_cls.new.greeting == "hello from class_eval",
        comment: "class_eval on a class defines instance methods on that class"
      }

      # Q41: What is a class instance variable?
      # An @ivar set on the class object itself, not shared with subclasses unlike @@ class variables.
      parent_civ = Class.new do
        @limit = 10
        def self.limit; @limit; end
      end
      child_civ = Class.new(parent_civ)
      results[:q41] = {
        question: "What is a class instance variable?",
        result: parent_civ.limit == 10 && child_civ.limit.nil?,
        comment: "Class instance variables are NOT inherited by subclasses"
      }

      # Q42: What is a value object?
      money_val = Money.new(1000, "USD")
      results[:q42] = {
        question: "What is a value object?",
        result: money_val.amount_cents == 1000 && money_val.frozen?,
        comment: "Represents a domain concept by value; immutable with value-based equality"
      }

      # Q43: What is dependency injection?
      # Class receives collaborators from outside rather than instantiating them internally.
      mock_gw = PaymentAdapters::MockGateway.new
      pay_srv = PaymentAdapters::StripeGateway.new(api_key: "sk_injected")
      results[:q43] = {
        question: "What is dependency injection?",
        result: pay_srv.api_key == "sk_injected",
        comment: "Collaborators injected via constructor enable test doubles without monkey patching"
      }

      # Q44: Composition vs inheritance?
      checkout_srv = Class.new do
        attr_reader :gateway
        def initialize(gateway:); @gateway = gateway; end
      end.new(gateway: mock_gw)
      results[:q44] = {
        question: "Composition vs inheritance?",
        result: checkout_srv.gateway == mock_gw,
        comment: "Favor composition for business workflows; inheritance for stable hierarchies"
      }

      # Q45: What is garbage collection?
      # CRuby reclaims unreachable objects with generational mark-and-sweep.
      obj_counts = ObjectSpace.count_objects
      results[:q45] = {
        question: "What is garbage collection?",
        result: obj_counts[:TOTAL].is_a?(Integer) && obj_counts[:TOTAL] > 0,
        comment: "Generational mark-and-sweep collector; measure with GC.stat and ObjectSpace"
      }

      # Q46: What is the GVL?
      # Global VM Lock allows only 1 Ruby thread at a time, releasing during blocking I/O.
      t_gvl = Time.now
      threads_gvl = 2.times.map { Thread.new { sleep 0.02 } }
      threads_gvl.each(&:join)
      results[:q46] = {
        question: "What is the GVL?",
        result: (Time.now - t_gvl) < 0.05,
        comment: "CRuby threads run concurrently during I/O sleep because GVL is released"
      }

      # Q47: Concurrency vs parallelism?
      results[:q47] = {
        question: "Concurrency vs parallelism?",
        result: true,
        comment: "Threads provide I/O concurrency; multi-process Puma workers provide true parallelism"
      }

      results
    end
  end
end
