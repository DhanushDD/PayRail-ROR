Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#index"

  # Authentication
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"

  # Main Web Portal
  get "dashboard", to: "dashboard#index"

  resources :transfers, only: [:new, :create, :show] do
    collection do
      get :lookup
    end
  end

  resources :deposits, only: [:create]

  resources :cards, only: [:index, :create] do
    member do
      patch :toggle_freeze
    end
  end

  get "ledger", to: "ledger#index"

  resources :payment_links, only: [:index, :create]
  get "checkout/:token", to: "payment_links#show", as: :checkout
  post "checkout/:token/pay", to: "payment_links#pay", as: :pay_checkout

  get "developer", to: "developer#index"
  post "developer/test_api", to: "developer#test_api"
end

