Rails.application.routes.draw do
  devise_for :users

  root "analytics/dashboard#index"

  get "/health", to: ->(_env) {
    [200, { "Content-Type" => "text/plain" }, ["OK"]]
  }

  resources :tickets

  namespace :api do
    resources :tickets, only: [:index]
  end

  namespace :analytics do
    get "dashboard", to: "dashboard#index", as: :dashboard
  end

  get "/network-dashboard", to: "dashboard#index"
  get "/pharma-dashboard", to: "analytics/dashboard#index"
  get "/new_ticket", to: "tickets#new"
end
