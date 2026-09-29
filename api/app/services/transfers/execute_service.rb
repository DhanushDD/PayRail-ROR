module Transfers
  class PaymentError < StandardError; end
  class InsufficientFundsError < PaymentError; end
  class InvariantViolationError < PaymentError; end
  class InvalidWalletError < PaymentError; end
  class WalletFrozenError < PaymentError; end

  class ExecuteService
    Result = Struct.new(:success?, :transfer, :error_message, :error_code, keyword_init: true)

    def self.call(**args)
      new(**args).call
    end

    def initialize(sender_wallet:, recipient_wallet:, amount_cents:, fee_cents: 0, description: nil, category: "transfer", idempotency_key: nil, metadata: {})
      @sender_wallet = sender_wallet
      @recipient_wallet = recipient_wallet
      @amount_cents = amount_cents.to_i
      @fee_cents = fee_cents.to_i
      @description = description.presence || "Transfer from #{sender_wallet&.user&.payrail_tag} to #{recipient_wallet&.user&.payrail_tag}"
      @category = category
      @idempotency_key = idempotency_key
      @metadata = metadata
    end

    def call
      validate_preconditions!

      ActiveRecord::Base.transaction do
        # 1. Deadlock-free pessimistic locking: lock wallets in ascending ID order
        locked_wallets = lock_wallets_in_order!
        locked_sender = locked_wallets[@sender_wallet.id]
        locked_recipient = locked_wallets[@recipient_wallet.id]

        total_deduction = @amount_cents + @fee_cents

        # 2. Re-verify balance with exclusive row lock
        if locked_sender.balance_cents < total_deduction
          raise InsufficientFundsError, "Insufficient wallet balance (Available: #{locked_sender.formatted_balance}, Required: #{format('$%.2f', total_deduction / 100.0)})"
        end

        # 3. Create the Transfer Record
        transfer = Transfer.create!(
          sender_wallet: locked_sender,
          recipient_wallet: locked_recipient,
          amount_cents: @amount_cents,
          fee_cents: @fee_cents,
          currency: locked_sender.currency,
          transfer_type: "p2p",
          status: "completed",
          description: @description,
          category: @category,
          idempotency_key: @idempotency_key,
          recipient_identifier: locked_recipient.user.payrail_tag,
          metadata: @metadata
        )

        # 4. Perform Atomic Balance Adjustments
        new_sender_balance = locked_sender.balance_cents - total_deduction
        new_recipient_balance = locked_recipient.balance_cents + @amount_cents

        locked_sender.update_columns(balance_cents: new_sender_balance, updated_at: Time.current)
        locked_recipient.update_columns(balance_cents: new_recipient_balance, updated_at: Time.current)

        # 5. Double-Entry Bookkeeping Ledger Entries
        debit_entry = LedgerEntry.create!(
          transfer: transfer,
          wallet: locked_sender,
          entry_type: "debit",
          amount_cents: total_deduction,
          balance_after_cents: new_sender_balance,
          description: "Debit: #{@description}"
        )

        credit_entry = LedgerEntry.create!(
          transfer: transfer,
          wallet: locked_recipient,
          entry_type: "credit",
          amount_cents: @amount_cents,
          balance_after_cents: new_recipient_balance,
          description: "Credit: #{@description}"
        )

        # 6. Verify Double-Entry Zero-Sum Invariant
        # Debits = Credits (+ platform fees)
        total_debits = debit_entry.amount_cents
        total_credits = credit_entry.amount_cents + @fee_cents
        unless total_debits == total_credits
          raise InvariantViolationError, "Double-entry ledger sum invariant violated! Debits: #{total_debits}, Credits: #{total_credits}"
        end

        # 7. Dispatch Webhooks
        dispatch_webhook_event(transfer)

        Result.new(success?: true, transfer: transfer, error_message: nil)
      end
    rescue PaymentError => e
      Result.new(success?: false, transfer: nil, error_message: e.message, error_code: e.class.name.demodulize.underscore)
    rescue => e
      Result.new(success?: false, transfer: nil, error_message: "Internal ledger processing error: #{e.message}", error_code: "internal_error")
    end

    private

    def validate_preconditions!
      raise InvalidWalletError, "Sender wallet cannot be nil" unless @sender_wallet
      raise InvalidWalletError, "Recipient wallet cannot be nil" unless @recipient_wallet
      raise InvalidWalletError, "Cannot transfer to the same wallet" if @sender_wallet.id == @recipient_wallet.id
      raise PaymentError, "Transfer amount must be strictly greater than $0.00" if @amount_cents <= 0
      raise WalletFrozenError, "Sender wallet is frozen" unless @sender_wallet.active?
      raise WalletFrozenError, "Recipient wallet is not active" unless @recipient_wallet.active?
    end

    def lock_wallets_in_order!
      ids = [@sender_wallet.id, @recipient_wallet.id].sort
      wallets = Wallet.where(id: ids).order(:id).lock.index_by(&:id)
      wallets
    end

    def dispatch_webhook_event(transfer)
      # Trigger webhook if recipient or sender has configured endpoints
      users = [transfer.sender_user, transfer.recipient_user].compact.uniq
      endpoints = WebhookEndpoint.where(user: users, active: true)

      endpoints.each do |endpoint|
        WebhookDelivery.create!(
          webhook_endpoint: endpoint,
          event_type: "transfer.completed",
          payload: {
            event: "transfer.completed",
            reference_id: transfer.reference_id,
            amount_cents: transfer.amount_cents,
            amount: transfer.formatted_amount,
            currency: transfer.currency,
            sender: transfer.sender_user&.payrail_tag,
            recipient: transfer.recipient_user&.payrail_tag,
            timestamp: Time.current.iso8601
          }.to_json,
          response_code: 200,
          status: "delivered"
        )
      end
    end
  end
end
