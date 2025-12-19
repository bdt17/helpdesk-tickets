Rails.application.routes.draw do
  root "home#index"
  
  get "login", to: "sessions#new"
  post "session", to: "sessions#create"
  delete "session", to: "sessions#destroy"
  get "logout", to: "sessions#destroy"
  
  get "dashboard", to: "home#dashboard"
  
  # Tickets (uncomment after scaffold)
  # resources :tickets
end
