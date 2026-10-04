# frozen_string_literal: true

# CircuitBreaker (Demonstrating Q147 - Fault Tolerance & Circuit Breaker Pattern)
#
# Key Architectural Features:
# 1. State Machine: Cycles between :closed, :open, and :half_open.
#    - :closed -> Normal operation. Failures increment failure_count.
#    - :open -> Threshold exceeded. Fails fast immediately without touching downstream dependency.
#    - :half_open -> Cooldown elapsed. Allows a single probe request through to check dependency recovery.
# 2. Thread Safety: Uses a Mutex to protect state transitions under concurrent worker calls.
# 3. Protects Resources: Stops worker threads and DB connections from piling up during vendor outages.
module Infrastructure
  class CircuitBreakerOpenError < StandardError; end

  class CircuitBreaker
    attr_reader :name, :failure_threshold, :cooldown_period, :failure_count, :last_failure_time, :state

    def initialize(name:, failure_threshold: 3, cooldown_period: 10)
      @name = name
      @failure_threshold = failure_threshold
      @cooldown_period = cooldown_period
      @failure_count = 0
      @last_failure_time = nil
      @state = :closed
      @mutex = Mutex.new
    end

    def run
      @mutex.synchronize do
        check_state_transition!
        if @state == :open
          raise CircuitBreakerOpenError, "Circuit breaker [#{@name}] is OPEN. Requests blocked to protect system."
        end
      end

      begin
        result = yield
        on_success
        result
      rescue => e
        on_failure
        raise e
      end
    end

    private

    def check_state_transition!
      if @state == :open && Time.now - @last_failure_time > @cooldown_period
        @state = :half_open
      end
    end

    def on_success
      @mutex.synchronize do
        @failure_count = 0
        @state = :closed
      end
    end

    def on_failure
      @mutex.synchronize do
        @failure_count += 1
        @last_failure_time = Time.now
        if @failure_count >= @failure_threshold || @state == :half_open
          @state = :open
        end
      end
    end
  end
end
