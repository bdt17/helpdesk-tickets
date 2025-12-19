require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module ThomasITHelpdesk
  class Application < Rails::Application
    config.load_defaults 8.1
    
    config.active_record.migration_error = false
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
