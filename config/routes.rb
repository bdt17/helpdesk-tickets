Rails.application.routes.draw do
  root "home#index"
  namespace :api do
    get '/health', to: 'health#index'
    get '/ai/status', to: 'ai#status'
  end
end
