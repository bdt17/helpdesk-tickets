Rails.application.routes.draw do
  root 'home#index'
  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  
  namespace :api do
    get 'health', to: 'health#index'
    get 'tickets', to: 'tickets#index'
    get 'drones', to: 'drones#index'
    get 'ai_status', to: 'ai#status'
  end
end
