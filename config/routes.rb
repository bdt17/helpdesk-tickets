Rails.application.routes.draw do
  root "home#index"
  
  # PHASE 16 - Working APIs
  namespace :api do
    get '/health', to: 'health#index'
    get '/ai/status', to: 'ai#status'
  end
  
  # FULL API SUITE - CORRECT SYNTAX
  namespace :api, path: '', defaults: {format: :json} do
    resources :tickets, only: [:index, :create]
    resources :users, only: [:index]
    resources :shipments, only: [:index, :create]
    get '/drones', to: 'drones#index'
    get '/drones/status', to: 'drones#status'
  end
  
  get '/status', to: 'status#index'
end
