Rails.application.routes.draw do
  root 'analytics/dashboard#index'
  
  # Analytics namespace (Pharma dashboard)
  namespace :analytics do
    resources :dashboard
  end
  
  # Network operations dashboard
  get '/network-dashboard', to: 'dashboard#index'
  
  # Network resources  
  resources :sites
  resources :devices
  
  # Devise authentication
  devise_for :users
end
