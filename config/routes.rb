Rails.application.routes.draw do
  root "home#index"
  
  # PHASE 16 APIs (LIVE)
  namespace :api do
    get '/health', to: 'health#index'
    get '/ai/status', to: 'ai#status'
  end
  
  # FULL API SUITE (Add these)
  namespace :api, path: '', defaults: {format: :json} do
    resources :tickets, only: [:index, :create, :show]
    resources :users, only: [:index, :show]
    resources :shipments, only: [:index, :create]
    resources :drones, only: [:index, :status]
  end
  
  # Health endpoints
  get '/status', to: 'status#index'
end
