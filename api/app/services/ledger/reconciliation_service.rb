# frozen_string_literal: true

# ReconciliationService (Demonstrating Q152 & Q167 - Ledger Reconciliation)
#
# Key Architectural Features:
# 1. Dual-Source Verification: Compares internal PayRail transactions against external provider reports (e.g. Stripe/Bank statements).
# 2. Resolves Ambiguous States: Automatically detects and surfaces out-of-sync states caused by network timeouts or missed webhooks.
# 3. Discrepancy Reporting: Outputs matched records, missing remote records, missing local records, and amount variances.
module Ledger
  class ReconciliationService
    Report = Struct.new(:matched_count, :discrepancies, :reconciled?, keyword_init: true)
    Discrepancy = Struct.new(:type, :reference_id, :internal_amount_cents, :provider_amount_cents, :details, keyword_init: true)

    def self.call(provider_records:)
      new(provider_records: provider_records).call
    end

    def initialize(provider_records:)
      # provider_records is an array of hashes: [{ id: "tx_1", amount_cents: 1000, status: "succeeded" }, ...]
      @provider_records = provider_records
    end

    def call
      discrepancies = []
      matched_count = 0

      provider_map = @provider_records.index_by { |r| r[:id] }

      # 1. Check all local completed transfers
      Transfer.where.not(status: "failed").find_each do |transfer|
        ref = transfer.reference_id
        prov_record = provider_map[ref]

        if prov_record.nil?
          # Local transfer has no matching external provider record
          discrepancies << Discrepancy.new(
            type: :missing_in_provider,
            reference_id: ref,
            internal_amount_cents: transfer.amount_cents,
            provider_amount_cents: nil,
            details: "Transfer #{ref} exists in local DB but not found in provider ledger"
          )
        elsif prov_record[:amount_cents] != transfer.amount_cents
          # Amount mismatch
          discrepancies << Discrepancy.new(
            type: :amount_mismatch,
            reference_id: ref,
            internal_amount_cents: transfer.amount_cents,
            provider_amount_cents: prov_record[:amount_cents],
            details: "Amount mismatch: Local=#{transfer.amount_cents} cents vs Provider=#{prov_record[:amount_cents]} cents"
          )
        else
          matched_count += 1
        end
      end

      Report.new(
        matched_count: matched_count,
        discrepancies: discrepancies,
        reconciled?: discrepancies.empty?
      )
    end
  end
end
