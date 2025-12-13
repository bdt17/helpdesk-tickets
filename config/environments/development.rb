Rails.application.configure do
  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local = true
  config.hosts << "172.59.202.107"
  config.hosts << "blkbxAS.lan"
end
