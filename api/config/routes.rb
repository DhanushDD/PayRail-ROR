Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root to: ->(_env) {
    [
      200,
      { "Content-Type" => "application/json" },
      [
        {
          name: "PayRail Core Payment & Authentication API",
          version: "1.0.0",
          engine: "Ruby on Rails 8.1 (Payments Fundamentals, Sidekiq, RSpec)",
          status: "healthy",
          endpoints: {
            auth: [
              "POST /api/v1/auth/sign_up",
              "POST /api/v1/auth/login",
              "DELETE /api/v1/auth/logout",
              "GET /api/v1/auth/me"
            ],
            payments: [
              "GET /api/v1/payments",
              "POST /api/v1/payments",
              "POST /api/v1/payments/deposit",
              "POST /api/v1/payments/:id/refund"
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

      resources :payments, only: [:index, :create] do
        collection do
          post :deposit
        end
        member do
          post :refund
        end
      end
    end
  end
end
