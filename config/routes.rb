Rails.application.routes.draw do
  root 'tickets#index'
  resources :tickets
  resources :knowledge_bases, only: :index
end
