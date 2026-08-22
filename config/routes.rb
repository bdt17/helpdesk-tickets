Rails.application.routes.draw do
  devise_for :users, skip: [:registrations]

  root "home#index"
  get "/health", to: ->(_env) { [200, { "Content-Type" => "text/plain" }, ["OK"]] }
  get "/home", to: "home#index", as: :home_index
  get "/dashboard", to: "home#dashboard", as: :home_dashboard

  resources :tickets
  get "/agents", to: "agents#index", as: :agents
  get "/reports", to: "reports#index", as: :reports_index

  namespace :api do
    resources :tickets, only: [:index]
    get "ai/status", to: "ai#status", as: :ai_status
  end
end
