Rails.application.routes.draw do
  root 'analytics/dashboard#index'
  
  # Your existing routes here (keep analytics/dashboard)
  namespace :analytics do
    resources :dashboard
  end
  
  # Network routes (SAFE - works with existing analytics)
  get '/network-dashboard', to: 'dashboard#index'
  resources :sites
  resources :devices
  
  # Devise routes (keep existing)
  devise_for :users
end
