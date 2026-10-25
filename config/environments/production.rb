require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.
  # DATABASE_URL must be set in the production environment (e.g. Render's
  # dashboard). No hardcoded fallback is used here — a missing DATABASE_URL
  # should fail loudly rather than silently default to a stale credential.

  # Code is not reloaded between requests.
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false

  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.log_tags = [ :request_id ]

  # Render terminates SSL at the edge and forwards plain HTTP internally.
  # assume_ssl tells Rails every request arrived over HTTPS regardless of
  # the internal hop, so force_ssl never issues a redirect (no loop) - it
  # only adds HSTS and marks the session/remember-me cookies Secure, which
  # they weren't before (a session cookie could be sent over plain HTTP if
  # anyone ever followed an http:// link).
  config.assume_ssl = true
  config.force_ssl = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Was left unconfigured, silently defaulting to Rails' file-store cache
  # under tmp/cache/ - ephemeral on Render, same problem Action Cable had
  # with Redis before that got fixed. Solid Cache was already in the
  # Gemfile, unused; this is also what backs rate_limit
  # (RegistrationsController, TeamController) with something durable
  # across restarts instead of resetting on every deploy.
  config.cache_store = :solid_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  # Solid Queue's tables live in this same database (single-database
  # configuration - Render only provisions one DATABASE_URL), so no
  # connects_to override is needed.
  config.active_job.queue_adapter = :solid_queue

  # Ticket attachments (see Ticket#attachments). Durable once
  # ACTIVE_STORAGE_ROOT points at a persistent disk (see config/storage.yml);
  # the rest of this note describes the default without it. Local disk, same as
  # dev/test - this makes uploads work immediately, but Render's web
  # service filesystem is ephemeral by default: anything under `storage/`
  # is wiped on every redeploy unless a persistent disk is attached
  # (Render add-on) or this is switched to an S3-compatible service in
  # config/storage.yml, neither of which this codebase can set up on its
  # own since both need real infrastructure/credentials this app doesn't
  # have. Don't treat client-uploaded attachments as durable until one of
  # those is actually in place.
  config.active_storage.service = :local

  # Links in every email (password reset, team invites, ticket
  # notifications) are built from this host. It used to be the Rails
  # placeholder "example.com", so every reset/invite link in production
  # pointed at someone else's domain.
  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "thomasinformationtechnology.com"), protocol: "https"
  }

  # Outgoing mail goes through whatever SMTP provider is configured in
  # the environment (Postmark, SendGrid, Resend, Mailgun, AWS SES - all
  # speak plain SMTP on 587). Until SMTP_ADDRESS is set there is no mail
  # server at all, so nothing is attempted - /reports' System health card
  # shows whether this is configured.
  if ENV["SMTP_ADDRESS"].present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.smtp_settings = {
      address: ENV["SMTP_ADDRESS"],
      port: ENV.fetch("SMTP_PORT", 587).to_i,
      user_name: ENV["SMTP_USERNAME"],
      password: ENV["SMTP_PASSWORD"],
      authentication: :plain,
      enable_starttls_auto: true
    }
  else
    config.action_mailer.perform_deliveries = false
  end

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
  config.active_record.async_query_executor = :global_thread_pool

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  # Sourced explicitly from ENV rather than relying on master.key-derived
  # credentials - carried over from main's fix, since Render's deployment
  # may not have a working master.key and this is what got production
  # booting there.
  config.secret_key_base = ENV.fetch("SECRET_KEY_BASE")
end
