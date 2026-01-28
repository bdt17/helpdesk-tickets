Rails.application.routes.draw do
  root 'analytics/dashboard#index'
  devise_for :users
  
  # ALL ROUTES NEEDED
  resources :tickets
  resources :sites  
  resources :devices
  get '/reports', to: 'reports#index'
  
  # API Phase 5
  namespace :api do
    resources :tickets, only: [:index]
  end
  
  # Dashboards
  namespace :analytics do
    resources :dashboard
  end
  get '/network-dashboard', to: 'dashboard#index'
end
