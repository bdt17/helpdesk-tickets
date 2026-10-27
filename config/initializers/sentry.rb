# Error alerts: unhandled exceptions in web requests and background jobs
# are reported to Sentry (sentry.io), which emails us - so a broken page
# or a failing email job is noticed before a client has to report it.
# Off unless SENTRY_DSN is set (Render > Environment), so dev and test
# never send anything.
if ENV["SENTRY_DSN"].present?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.environment = Rails.env
    config.breadcrumbs_logger = [ :active_support_logger ]
    # No client emails, IPs or cookies in reports.
    config.send_default_pii = false
    # Errors only, no performance tracing - keeps us well inside the free tier.
    config.traces_sample_rate = 0.0
  end
end
