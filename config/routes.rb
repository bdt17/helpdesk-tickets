Rails.application.routes.draw do
  root to: "home#index"
  
  namespace :api do
    get :health, controller: 'health'
    resources :tickets, only: :index
    resources :drones, only: :index
    get :ai_status, to: 'ai#status'
  end
end
