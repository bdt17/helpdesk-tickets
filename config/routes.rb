Rails.application.routes.draw do
  root 'home#index'
  
  get 'tech/dashboard', to: 'tech/dashboard#index'
  post 'tech/swap_device', to: 'tech/dashboard#swap_device'
  
  namespace :api do
    get 'health', to: 'health#index'
    get 'tickets', to: 'tickets#index'
    get 'drones', to: 'drones#index'
    get 'ai_status', to: 'ai#status'
  end
end
