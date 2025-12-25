Rails.application.routes.draw do
  root "home#index"
  
  # API endpoints (PHASE 16)
  namespace :api do
    get '/health', to: 'health#index'
    get '/ai/status', to: 'ai#status'
  end
  
  # PHASE 2 - Tickets (add later)
  resources :tickets, only: [:index, :create]
end
