# Render REQUIRES 0.0.0.0 binding
port = ENV.fetch("PORT") { 3000 }
bind "tcp://0.0.0.0:#{port}"

workers 1
threads 1, 1

preload_app!
environment ENV.fetch("RAILS_ENV") { "production" }

on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end
