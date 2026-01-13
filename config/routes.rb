Rails.application.routes.draw do
  devise_for :users
  
  namespace :analytics do
    get '/', to: 'dashboard#index', as: :dashboard
  end
  
  # ALL routes MUST be INSIDE this block:
  get '/reports', to: 'reports#index'
  
  namespace :api do 
    get '/ai/status', to: 'api/ai#status'
    post '/ai/categorize', to: 'api/ai#categorize'
  end
  
  root to: 'analytics/dashboard#index'
end
