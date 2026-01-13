Rails.application.routes.draw do
  devise_for :users
  namespace :api do
    get "ai/status"
  end
  get "reports/index"
  root "home#index"
  
  get "login", to: "sessions#new"
  post "session", to: "sessions#create"
  delete "session", to: "sessions#destroy"
  get "logout", to: "sessions#destroy"
  
  get "dashboard", to: "home#dashboard"
  
  # Tickets (uncomment after scaffold)
  # resources :tickets
end
get '/reports', to: 'reports#index'
namespace :api do get '/ai/status', to: 'api/ai#status' end
post '/api/ai/categorize', to: 'api/ai#categorize'
namespace :api do get '/ai/status', to: 'api/ai#status' end
namespace :api do get '/ai/status', to: 'api/ai#status' end
