Rails.application.configure do
  config.force_ssl = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.cache_classes = true
  config.eager_load = true
  config.log_level = :info
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
  
  # ASSET PIPELINE FIX
  config.assets.compile = true
  config.assets.debug = false
end
