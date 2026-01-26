Rails.application.routes.draw do
  devise_for :users
  # Thomas IT Custom Authentication (DISABLE DEVISE)
  get 'login', to: 'sessions#new', as: 'login'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy', as: 'logout'

  # Dashboard (root)
  root 'analytics/dashboard#index'

  # Analytics namespace
  namespace :analytics do
    get '/', to: 'dashboard#index', as: :dashboard
  end

  # Reports
  get '/reports', to: 'reports#index'

  # API namespace
  namespace :api do
    get '/ai/status', to: 'api/ai#status'
    post '/ai/categorize', to: 'api/ai#categorize'
  end

  # Tickets (assuming you have tickets)
  resources :tickets

  # DISABLE DEVISE - NO LONGER NEEDED
  # devise_for :users
end

get 'dashboard', to: 'dashboard#index'
resources :sites
resources :devices
