Rails.application.configure do
  config.eager_load = true
  config.cache_classes = true
  config.consider_all_requests_local = false
  config.force_ssl = false
config.active_record.migration_error = false

end
