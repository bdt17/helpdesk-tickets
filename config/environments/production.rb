Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_caching = false
  config.action_mailer.smtp_settings = {
    address: 'smtp.gmail.com',
    port: 587,
    domain: 'gmail.com',
    user_name: 'brett.thomas29.97@gmail.com',
    password: ENV['SMTP_PASSWORD'],
    authentication: 'login',
    enable_starttls_auto: true
  }
  config.action_mailer.default_url_options = { host: 'helpdesk-tickets-yfpr.onrender.com' }

  config.active_record.migration_error = :page_load
  config.log_level = :info
  config.log_tags = [ :request_id ]
  config.assets.compile = true
  config.force_ssl = false
end


Rails.application.configure do
  config.eager_load = true  # ← Fix warning
  
  # Cache store for production
  config.cache_store = :memory_store
  
  # Render Puma settings
  config.public_file_server.enabled = true
end



Rails.application.configure do
  config.eager_load = true
  
  # Fix cache_store - use symbol/hash format
  config.cache_store = :memory_store
  
  config.force_ssl = false  # Render handles SSL
end

# Rails 8.1 multi-DB fix
config.active_record.database_configurations = {
  'production' => { 'primary' => { 'adapter' => 'postgresql', 'database' => ENV['DATABASE_URL'] } }
}

# Eager load required
config.eager_load = true
