Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#index"

  # Authentication (Sign Up / Login / Logout)
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"
  get "sign_up", to: "registrations#new"
  post "sign_up", to: "registrations#create"

  # Payment Gateway Dashboard & Actions
  get "dashboard", to: "dashboard#index"
  resources :payments, only: [:create] do
    collection do
      post :deposit
    end
    member do
      post :capture
      post :void
      post :refund
    end
  end
end
