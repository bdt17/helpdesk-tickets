Rails.application.configure do
  # Existing settings (keep these)
  config.log_level = :info
  config.log_tags  = [ :request_id ]
  config.action_mailer.perform_caching = false

  # SECURITY FIXES (inside block)
  config.force_ssl = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  config.cache_classes                     = true
  config.eager_load                        = true
  config.server_timing = true

  # Render.com settings
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
  config.assets.compile = true
end
