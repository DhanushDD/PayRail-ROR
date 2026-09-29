Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root to: ->(_env) {
    [
      200,
      { "Content-Type" => "application/json" },
      [
        {
          name: "PayRail Core Payment Engine API",
          version: "1.0.0",
          engine: "Ruby on Rails 8.1 (Enterprise Double-Entry Ledger)",
          status: "healthy",
          endpoints: {
            auth: ["/api/v1/auth/register", "/api/v1/auth/login", "/api/v1/auth/me"],
            transfers: ["/api/v1/transfers", "/api/v1/transfers/lookup_recipient"],
            wallets: ["/api/v1/wallets", "/api/v1/wallets/:id/ledger"],
            deposits: ["/api/v1/deposits"],
            virtual_cards: ["/api/v1/cards", "/api/v1/cards/:id/toggle_freeze"],
            payment_links: ["/api/v1/payment_links", "/api/v1/payment_links/:token"],
            analytics: ["/api/v1/analytics/overview"],
            webhooks: ["/api/v1/webhooks"]
          }
        }.to_json
      ]
    ]
  }

  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      get "auth/me", to: "auth#me"

      resources :wallets, only: [:index, :show] do
        member do
          get :ledger
        end
      end

      resources :transfers, only: [:index, :show, :create] do
        collection do
          get :lookup_recipient
        end
      end

      resources :deposits, only: [:create]

      resources :cards, only: [:index, :create] do
        member do
          patch :toggle_freeze
        end
      end

      resources :payment_links, only: [:index, :create]
      get "payment_links/:token", to: "payment_links#show"
      post "payment_links/:token/pay", to: "payment_links#pay"

      get "analytics/overview", to: "analytics#overview"
      resources :webhooks, only: [:index, :create]
    end
  end
end

