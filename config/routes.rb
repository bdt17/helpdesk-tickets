# config/routes.rb
Rails.application.routes.draw do
  # Devise FIRST (convention)
  devise_for :users

  # Root
  root 'analytics/dashboard#index'

  # REST Resources (fixes 404s)
  resources :tickets
  resources :sites  
  resources :devices

  # Reports
  get '/reports', to: 'reports#index'

  # API
  namespace :api do
    resources :tickets, only: [:index]
  end

  # Dashboards (fixes redirects)
  namespace :analytics do
    get '/dashboard', to: 'dashboard#index', as: :dashboard
  end
  
  get '/network-dashboard', to: 'dashboard#index'
  get '/pharma-dashboard', to: 'analytics/dashboard#index'

  # Legacy routes your tests expect
  get '/tickets', to: 'tickets#index'
  get '/new_ticket', to: 'tickets#new'
end
