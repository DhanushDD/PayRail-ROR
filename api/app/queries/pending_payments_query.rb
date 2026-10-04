# frozen_string_literal: true

# PendingPaymentsQuery (Demonstrating Q78 - Query Objects)
#
# Key Architectural Features:
# 1. Composable Relations: Encapsulates complex SQL/ActiveRecord filtering into an isolated, reusable object.
# 2. Always Returns a Relation: Allows callers to chain additional ActiveRecord methods (`.limit`, `.order`, `.where`).
# 3. Keeps Models Thin (Q80): Prevents bloating ActiveRecord models with one-off query methods.
module Queries
  class PendingPaymentsQuery
    def self.call(relation = Transfer.all, user: nil, created_before: nil)
      new(relation).call(user: user, created_before: created_before)
    end

    def initialize(relation = Transfer.all)
      @relation = relation
    end

    def call(user: nil, created_before: nil)
      scope = @relation.where(status: "pending")

      if user.present?
        wallet_ids = user.wallets.select(:id)
        scope = scope.where("sender_wallet_id IN (:ids) OR recipient_wallet_id IN (:ids)", ids: wallet_ids)
      end

      if created_before.present?
        scope = scope.where("created_at < ?", created_before)
      end

      scope.order(created_at: :desc)
    end
  end
end
