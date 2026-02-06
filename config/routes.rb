Rails.application.routes.draw do
  root "home#index"  # Serves your public/index.html
  get '/health', to: ->(_env) { [200, {'Content-Type' => 'text/plain'}, ['OK']] }
end
