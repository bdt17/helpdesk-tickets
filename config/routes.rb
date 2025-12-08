Rails.application.routes.draw do
  root 'tickets#new'                 # Homepage = ticket form
  resources :tickets, only: [:index, :new, :create]
end
