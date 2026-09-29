module Deposits
  class ProcessService
    Result = Struct.new(:success?, :transfer, :error_message, keyword_init: true)

    def self.call(**args)
      new(**args).call
    end

    def initialize(wallet:, amount_cents:, payment_method: "card", description: nil)
      @wallet = wallet
      @amount_cents = amount_cents.to_i
      @payment_method = payment_method
      @description = description.presence || "Instant Deposit via #{payment_method.titleize}"
    end

    def call
      return Result.new(success?: false, error_message: "Deposit amount must be positive") if @amount_cents <= 0
      return Result.new(success?: false, error_message: "Wallet is not active") unless @wallet.active?

      ActiveRecord::Base.transaction do
        @wallet.lock!

        new_balance = @wallet.balance_cents + @amount_cents
        @wallet.update_columns(balance_cents: new_balance, updated_at: Time.current)

        transfer = Transfer.create!(
          sender_wallet_id: nil, # external rail
          recipient_wallet: @wallet,
          amount_cents: @amount_cents,
          fee_cents: 0,
          currency: @wallet.currency,
          transfer_type: "deposit",
          status: "completed",
          category: "deposit",
          description: @description,
          metadata: { rail: @payment_method, processed_at: Time.current.iso8601 }
        )

        LedgerEntry.create!(
          transfer: transfer,
          wallet: @wallet,
          entry_type: "credit",
          amount_cents: @amount_cents,
          balance_after_cents: new_balance,
          description: "Deposit Credit: #{@description}"
        )

        Result.new(success?: true, transfer: transfer)
      end
    rescue => e
      Result.new(success?: false, error_message: e.message)
    end
  end
end
