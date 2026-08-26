Rails.application.routes.draw do
  devise_for :users, skip: [ :registrations ]
  # Sign-up only (no self-service edit/destroy account yet) — routed through
  # RegistrationsController, which hardcodes new accounts to the client role.
  devise_scope :user do
    get "signup", to: "registrations#new", as: :new_user_registration
    post "signup", to: "registrations#create", as: :user_registration
  end

  root "home#index"
  get "/health", to: ->(_env) { [ 200, { "Content-Type" => "text/plain" }, [ "OK" ] ] }
  get "/home", to: "home#index", as: :home_index
  get "/dashboard", to: "dashboard#index", as: :dashboard

  resources :tickets do
    resources :comments, only: [ :create ]
  end
  get "/agents", to: "agents#index", as: :agents
  get "/reports", to: "reports#index", as: :reports_index

  get "/billing", to: "billing#show", as: :billing
  post "/billing/checkout/:plan", to: "billing#checkout", as: :billing_checkout
  get "/billing/success", to: "billing#success", as: :billing_success
  post "/billing/portal", to: "billing#portal", as: :billing_portal

  namespace :api do
    resources :tickets, only: [ :index ]
    get "ai/status", to: "ai#status", as: :ai_status
  end

  namespace :webhooks do
    post "stripe", to: "stripe#create"
  end
end
