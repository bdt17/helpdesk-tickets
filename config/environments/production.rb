Rails.application.configure do
  # Core production settings
  config.log_level = :info
  config.log_tags  = [ :request_id ]
  config.action_mailer.perform_caching = false

  # SECURITY (HSTS + hardening)
  config.force_ssl = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Performance
  config.cache_classes = true
  config.eager_load = true
  config.server_timing = true

  # Render.com
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
  config.assets.compile = true
end
