Rails.application.routes.draw do
  devise_for :users
  
  # Tech routes (require auth later)
  get '/tech/dashboard', to: 'tech#dashboard'
  get '/tech_kb', to: 'tech#kb'
  
  # Client dashboard
  get '/dashboard', to: 'dashboard#show'
  
  root to: "tech#dashboard"
end

