Rails.application.routes.draw do
  root 'tickets#new'                 # Homepage = ticket form
  resources :tickets, only: [:index, :new, :create]
end
authenticated :user do
  root to: 'tickets#client_dashboard', as: :client_root
end

get '/tech/dashboard', to: 'tickets#tech_dashboard'
