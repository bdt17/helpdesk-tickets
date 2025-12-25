Rails.application.routes.draw do
  namespace :api do
    get '/ai/status', to: 'ai#status'
  end
  # ... your other routes
end

namespace :api do
  get '/health', to: 'health#index'
  get '/ai/status', to: 'ai#status'
end
