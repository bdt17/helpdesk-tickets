Rails.application.configure do
  config.eager_load = true
  config.cache_classes = true
  config.consider_all_requests_local = true
  config.force_ssl = false
config.active_record.migration_error = false
config.consider_all_requests_local = true
config.action_dispatch.show_exceptions = true

end
