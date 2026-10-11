class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  attr_reader :current_user

  def authenticate_api_user!
    token = extract_token_from_header
    api_key = request.headers["X-API-Key"].presence

    if token.present?
      decoded = JwtService.decode(token)
      if decoded && (@current_user = User.find_by(id: decoded[:user_id]))
        return
      end
    elsif api_key.present?
      if (@current_user = User.find_by(api_key: api_key))
        return
      end
    end

    render json: {
      error: "Unauthorized",
      message: "Valid Bearer JWT token or X-API-Key header required."
    }, status: :unauthorized
  end

  private

  def extract_token_from_header
    auth_header = request.headers["Authorization"]
    return nil unless auth_header.present?
    auth_header.split(" ").last if auth_header.start_with?("Bearer ")
  end

  def render_not_found(exception)
    render json: { error: "Not Found", message: exception.message }, status: :not_found
  end

  def render_bad_request(exception)
    render json: { error: "Bad Request", message: exception.message }, status: :bad_request
  end
end
