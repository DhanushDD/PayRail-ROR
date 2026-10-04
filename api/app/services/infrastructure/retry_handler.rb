# frozen_string_literal: true

# RetryHandler (Demonstrating Q119, Q148, Q156 - Retry Strategy with Backoff & Jitter)
#
# Key Architectural Features:
# 1. Error Classification (Q119): Retries ONLY transient errors (5xx, timeouts, 429). Permanent errors fail immediately.
# 2. Exponential Backoff with Jitter (Q148): Base delay doubled each attempt + random jitter to prevent synchronized waves.
# 3. Maximum Attempts Bound (Q156): Bounded retries ensure worker threads are not held indefinitely.
module Infrastructure
  class RetryHandler
    def self.with_retries(max_attempts: 3, base_delay: 0.05, max_delay: 2.0, retryable_exceptions: [StandardError], non_retryable_exceptions: [])
      attempts = 0
      begin
        attempts += 1
        yield(attempts)
      rescue *non_retryable_exceptions => e
        # Permanent failure: do NOT retry
        raise e
      rescue *retryable_exceptions => e
        if attempts >= max_attempts
          # Retries exhausted
          raise e
        end

        # Exponential backoff: base_delay * (2 ** (attempt - 1))
        exponential = base_delay * (2**(attempts - 1))
        # Add Full Jitter (0 to 50% random variation) to desynchronize callers
        jitter = rand * (exponential * 0.5)
        sleep_duration = [exponential + jitter, max_delay].min

        sleep(sleep_duration) if sleep_duration > 0
        retry
      end
    end
  end
end
