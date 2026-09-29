class JwtService
  SECRET_KEY = Rails.application.secret_key_base || "payrail_super_secret_jwt_key_2026"

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY, "HS256")
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: "HS256" })[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError => e
    nil
  end
end
