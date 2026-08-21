require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false

  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.log_tags = [:request_id]

  config.force_ssl = false

  config.active_record.dump_schema_after_migration = false
  config.active_record.async_query_executor = :global_thread_pool

  config.secret_key_base = ENV.fetch("SECRET_KEY_BASE")
end
