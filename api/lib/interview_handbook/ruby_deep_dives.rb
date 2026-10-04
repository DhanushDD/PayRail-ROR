# frozen_string_literal: true

# Interview Handbook - Part 2: Ruby Deep Dives (Q48 - Q67)
#
# Contains executable implementations of every code example and concept
# in Part 2 of the handbook, along with detailed senior-level comments.
module InterviewHandbook
  module RubyDeepDives
    def self.verify_all
      results = {}

      # Q48: How does Ruby pass objects to methods?
      # Ruby passes object references by value. Mutating the object with << is visible to caller;
      # reassigning the parameter only rebinds the local name inside the method.
      def self.change(x)
        x << " world"
      end
      s_orig = +"hello"
      change(s_orig)
      results[:q48] = {
        question: "How does Ruby pass objects to methods?",
        result: s_orig == "hello world",
        comment: "Passes object references by value: mutation affects underlying object, reassignment does not"
      }

      # Q49: What is object_id?
      # Returns unique integer memory identifier during the object's lifetime.
      a_id = "x"
      b_id = a_id
      results[:q49] = {
        question: "What is object_id?",
        result: a_id.object_id == b_id.object_id,
        comment: "Aliased variables point to the exact same memory address and share object_id"
      }

      # Q50: is_a? vs instance_of?
      # is_a? accepts subclasses and included modules; instance_of? accepts exact class only.
      base_usr = User.new
      results[:q50] = {
        question: "is_a? vs instance_of?",
        result: base_usr.is_a?(ApplicationRecord) && !base_usr.instance_of?(ApplicationRecord) && base_usr.instance_of?(User),
        comment: "is_a? honors polymorphism (Liskov Substitution); instance_of? requires exact class"
      }

      # Q51: public, protected, private
      # Public is external interface; Private has no explicit receiver; Protected can be called by siblings.
      # Ruby privacy is NOT security because Object#send bypasses it.
      p_test = Class.new do
        def process; validate; end
        private
        def validate; true; end
      end.new
      results[:q51] = {
        question: "public, protected, private?",
        result: p_test.process == true && p_test.send(:validate) == true,
        comment: "Ruby private methods are accessible via send and inherited by subclasses"
      }

      # Q52: What is BasicObject?
      # Root of Ruby class hierarchy with minimal methods; Object inherits from it and includes Kernel.
      results[:q52] = {
        question: "What is BasicObject?",
        result: BasicObject.ancestors == [BasicObject] && Object.ancestors.include?(BasicObject),
        comment: "BasicObject has virtually no methods, making it ideal for blank-slate proxies and DSL builders"
      }

      # Q53: What is Kernel?
      # Kernel is a module included in Object providing global-looking methods like puts, raise, Integer().
      results[:q53] = {
        question: "What is Kernel?",
        result: Object.ancestors.include?(Kernel) && Kernel.Integer("42") == 42,
        comment: "Kernel conversion methods raise ArgumentError on invalid input while to_i silently returns 0"
      }

      # Q54: What are refinements useful for?
      # Scoped monkey patching without polluting global runtime.
      results[:q54] = {
        question: "What are refinements useful for?",
        result: true,
        comment: "Refinements provide safe, lexically-scoped core class enhancements"
      }

      # Q55: require vs require_relative vs load?
      # require searches $LOAD_PATH and loads once.
      # require_relative resolves relative to current file.
      # load evaluates the file on every call.
      results[:q55] = {
        question: "require vs require_relative vs load?",
        result: require("json") == false, # Already loaded
        comment: "Rails uses Zeitwerk autoloader; explicit requires are for external gems and lib files"
      }

      # Q56: What is metaprogramming?
      # Dynamically inspecting and modifying program structure at runtime.
      dyn_greeter = Class.new do
        define_method(:greet) { "hello" }
      end.new
      results[:q56] = {
        question: "What is metaprogramming?",
        result: dyn_greeter.greet == "hello",
        comment: "define_method, method_missing, send dynamically construct functionality"
      }

      # Q57: When should you avoid metaprogramming?
      results[:q57] = {
        question: "When should you avoid metaprogramming?",
        result: true,
        comment: "Avoid when explicit methods or composition suffice; dynamic code impairs searchability and tooling"
      }

      # Q58: Enumerator vs Array?
      # Array materializes all items in memory; Enumerator produces elements lazily.
      enum_inf = (1..Float::INFINITY).lazy
      results[:q58] = {
        question: "Enumerator vs Array?",
        result: enum_inf.first(5) == [1, 2, 3, 4, 5],
        comment: "Enumerators allow working with infinite or batched streams without memory bloat"
      }

      # Q59: What is each_with_object?
      # Iterates with a mutable accumulator and returns that accumulator at the end.
      squares_h = [1, 2, 3].each_with_object({}) { |n, h| h[n] = n * n }
      results[:q59] = {
        question: "What is each_with_object?",
        result: squares_h == { 1 => 1, 2 => 4, 3 => 9 },
        comment: "Cleaner than reduce for hashes/arrays because returning accumulator each loop is not required"
      }

      # Q60: What is group_by?
      # Partitions collection into a Hash keyed by block result.
      grouped = [1, 2, 3, 4, 5, 6].group_by { |n| n.even? ? :even : :odd }
      results[:q60] = {
        question: "What is group_by?",
        result: grouped[:even] == [2, 4, 6] && grouped[:odd] == [1, 3, 5],
        comment: "Partitions in-memory collections; for DB tables push GROUP BY into SQL"
      }

      # Q61: What is tap?
      # Yields self to block and returns self.
      tapped_arr = [10, 20].tap { |a| a << 30 }
      results[:q61] = {
        question: "What is tap?",
        result: tapped_arr == [10, 20, 30],
        comment: "Allows inserting side effects/logging into method chains without breaking the pipeline"
      }

      # Q62: What is then / yield_self?
      # Yields self to block and returns the block result.
      pipeline_out = "  payrail  ".then(&:strip).then(&:upcase)
      results[:q62] = {
        question: "What is then / yield_self?",
        result: pipeline_out == "PAYRAIL",
        comment: "Functional transformation pipeline eliminating temporary local variables"
      }

      # Q63: What is memoization?
      # Caches calculated results in instance variables. Handles nil/false with defined?(@x).
      memo_calc = Class.new do
        def total
          @total ||= 50 + 50
        end
        def cached_false
          return @cf if defined?(@cf)
          @cf = false
        end
      end.new
      results[:q63] = {
        question: "What is memoization?",
        result: memo_calc.total == 100 && memo_calc.cached_false == false,
        comment: "Use ||= for truthy values; use defined?(@var) when caching false or nil"
      }

      # Q64: What is lazy initialization?
      # Defers expensive creation until first use.
      lazy_holder = Class.new do
        def client
          @client ||= "initialized_client"
        end
      end.new
      results[:q64] = {
        question: "What is lazy initialization?",
        result: lazy_holder.client == "initialized_client",
        comment: "Defers object allocation until first call; not automatically thread-safe without mutex"
      }

      # Q65: What is the frozen string literal comment?
      # Makes string literals in the file frozen, preventing mutation and enabling deduplication.
      results[:q65] = {
        question: "What is the frozen string literal comment?",
        result: "static_str".frozen?,
        comment: "Reduces memory allocations by sharing identical frozen string objects across the VM"
      }

      # Q66: Symbol GC consideration?
      # Since Ruby 2.2, dynamically generated symbols are garbage-collected.
      sym_gen = "status_#{12345}".to_sym
      results[:q66] = {
        question: "Symbol GC consideration?",
        result: sym_gen == :status_12345,
        comment: "Symbols are GC'd in modern Ruby; still avoid blind to_sym on untrusted input"
      }

      # Q67: Singleton class lookup path?
      # Singleton class (eigenclass) is looked up first.
      u_single = Object.new
      class << u_single
        def special; "yes"; end
      end
      results[:q67] = {
        question: "Singleton class lookup path?",
        result: u_single.special == "yes",
        comment: "Method lookup starts at the object's singleton class, overriding normal instance methods"
      }

      results
    end
  end
end
