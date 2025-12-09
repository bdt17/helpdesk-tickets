Rails.application.configure do
  # Code reloading disabled by default
  config.cache_classes = true

  # Eager load code on boot
  config.eager_load = true

  # Full error reports disabled
  config.consider_all_requests_local = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Use default logger
  config.log_level = :info

  # Prepend log lines with date/time
  config.log_tags = [ :request_id ]

  # Render assets in production without requiring secret key
  config.assets.compile = false

  # Set static assets cache expiry
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Force all access to the app over SSL
  config.force_ssl = false

  # Ignore bad email addresses
  config.action_mailer.smtp_settings = {
    address:              'smtp.gmail.com',
    port:                 587,
    domain:               'example.com',
    user_name:            'your-email@gmail.com',
    password:             'your-password',
    authentication:       'plain',
    enable_starttls_auto: true
  }
end
