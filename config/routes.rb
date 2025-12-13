Rails.application.routes.draw do
  devise_for :users
  root "tickets#index"
  
  resources :tickets do
    resources :comments, only: [:create]
  end
  
  resources :knowledge_bases
  resources :projects, only: [:index, :new, :create, :show]
  
  get 'techs', to: 'techs#index', as: 'techs'
  get 'clients', to: 'clients#index', as: 'clients'
end
