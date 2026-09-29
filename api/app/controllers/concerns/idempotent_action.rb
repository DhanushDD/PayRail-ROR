module IdempotentAction
  extend ActiveSupport::Concern

  def handle_idempotency
    idempotency_key = request.headers["Idempotency-Key"]
    return yield if idempotency_key.blank?

    record = IdempotencyRecord.find_by(key: idempotency_key)
    if record
      response.set_header("X-Idempotency-Replay", "true")
      render json: record.parsed_response_body, status: record.response_code
      return
    end

    yield

    if response.successful? && idempotency_key.present?
      IdempotencyRecord.create(
        key: idempotency_key,
        request_path: request.path,
        request_params_hash: Digest::SHA256.hexdigest(request.raw_post.to_s),
        response_code: response.status,
        response_body: response.body
      )
    end
  end
end
