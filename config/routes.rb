Rails.application.routes.draw do
  # Knowledge Base
  get '/tech_kb', to: 'tech_kb#index', as: :tech_kb
  get '/tech_kb/search', to: 'tech_kb#search', as: :tech_kb_search
  
  # Client Status Portal
  get '/clients/status/:id', to: 'client_status#show', as: :client_status
  
  # Dashboards
  get 'dashboard', to: 'tickets#client_dashboard', as: :client_dashboard
  get 'tech/dashboard', to: 'tickets#tech_dashboard', as: :tech_dashboard
  
  # Tickets
  resources :tickets, only: [:index, :new, :create, :show]
  
  root 'tickets#index'
end
