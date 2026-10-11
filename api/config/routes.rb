Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root to: ->(_env) {
    [
      200,
      { "Content-Type" => "application/json" },
      [
        {
          name: "PayRail Authentication API",
          version: "1.0.0",
          engine: "Ruby on Rails 8.1 (RESTful API, Sidekiq, RSpec)",
          status: "healthy",
          endpoints: {
            auth: [
              "POST /api/v1/auth/sign_up",
              "POST /api/v1/auth/register",
              "POST /api/v1/auth/login",
              "DELETE /api/v1/auth/logout",
              "GET /api/v1/auth/me"
            ]
          }
        }.to_json
      ]
    ]
  }

  namespace :api do
    namespace :v1 do
      post "auth/sign_up", to: "auth#sign_up"
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      delete "auth/logout", to: "auth#logout"
      get "auth/me", to: "auth#me"
    end
  end
end
