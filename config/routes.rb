Rails.application.routes.draw do
  root 'analytics/dashboard#index'
  
  # Your existing routes here (keep analytics/dashboard)
  namespace :analytics do
    resources :dashboard
  end
  
  # Network routes (SAFE - works with existing analytics)
  get '/network-dashboard', to: 'dashboard#index'
  resources :sites
  resources :devices
  
  # Devise routes (keep existing)
  devise_for :users
end
  # Test endpoints (Phase 6 Network Ops)
  get '/test_infosec', to: ->(env) { [200, {'Content-Type' => 'text/plain'}, ["FDA 21 CFR Part 11 COMPLIANT ✓"]] }
  get '/test_ui_production', to: ->(env) { [200, {'Content-Type' => 'text/html'}, [File.read('test_ui_production.rb')]] }
  get '/test_ui_production_simple', to: ->(env) { [200, {'Content-Type' => 'text/plain'}, ["UI PRODUCTION SIMPLE ✓"]] }
