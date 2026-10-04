# frozen_string_literal: true

# CursorPaginator (Demonstrating Q134 & Q135 - Fast, Scalable Keyset Pagination)
#
# Key Architectural Features:
# 1. Eliminates OFFSET Degradation (Q135): Instead of making the DB scan and discard thousands of rows,
#    keyset pagination seeks directly to indexed coordinates using composite ordering: (created_at DESC, id DESC).
# 2. Deterministic Tie-Breaking: Uses `id` alongside `created_at` so identical timestamps never cause skipped or duplicated records.
# 3. Opaque Cursors: Encodes (timestamp, id) into a base64 cursor token returned in API responses.
module Infrastructure
  class CursorPaginator
    PageResult = Struct.new(:records, :next_cursor, :has_more?, keyword_init: true)

    def self.paginate(relation, cursor: nil, limit: 20)
      new(relation, cursor: cursor, limit: limit).paginate
    end

    def initialize(relation, cursor: nil, limit: 20)
      @relation = relation
      @cursor = cursor
      @limit = [limit.to_i, 1].max
    end

    def paginate
      scope = @relation.order(created_at: :desc, id: :desc)

      if @cursor.present?
        created_at, id = decode_cursor(@cursor)
        if created_at && id
          scope = scope.where(
            "created_at < :ts OR (created_at = :ts AND id < :id)",
            ts: created_at, id: id
          )
        end
      end

      # Fetch limit + 1 to detect whether a next page exists without running a COUNT query
      records = scope.limit(@limit + 1).to_a
      has_more = records.size > @limit
      page_records = records.first(@limit)

      next_cursor = if has_more && page_records.last
                      encode_cursor(page_records.last.created_at, page_records.last.id)
                    else
                      nil
                    end

      PageResult.new(
        records: page_records,
        next_cursor: next_cursor,
        has_more?: has_more
      )
    end

    private

    def encode_cursor(timestamp, id)
      Base64.strict_encode64("#{timestamp.iso8601(6)}|#{id}")
    end

    def decode_cursor(cursor_str)
      decoded = Base64.strict_decode64(cursor_str)
      ts_str, id_str = decoded.split("|", 2)
      [Time.zone.parse(ts_str), id_str.to_i]
    rescue => _e
      [nil, nil]
    end
  end
end
