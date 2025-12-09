Rails.application.routes.draw do
  get "tech_kb/index"
  get "tech_kb/search"

get '/clients/status/:id', to: 'client_status#show', as: :client_status


  get "client_status/show"
  # Client dashboard
  get 'dashboard', to: 'tickets#client_dashboard', as: :client_dashboard
  
  # Tech dashboard  
  get 'tech/dashboard', to: 'tickets#tech_dashboard', as: :tech_dashboard
  
  # Basic ticket routes
  resources :tickets, only: [:index, :new, :create, :show]
  
  # Root path
  root 'tickets#index'
end
