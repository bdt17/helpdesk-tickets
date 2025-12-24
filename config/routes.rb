Rails.application.routes.draw do
  root "home#index"
end
get '/api/ai/status', to: 'api/ai#status'
get '/api/ai/status', to: 'api/ai#status'
