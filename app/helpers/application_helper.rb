module ApplicationHelper
  # Absolute URL on the site's real domain, for canonical links and the
  # sitemap. In production that's APP_HOST (same as mailer links), not
  # whatever host the request came in on - Render's *.onrender.com address
  # serves the same pages, and search engines should only index one.
  def public_url(path = request.path)
    base = Rails.env.production? ? "https://#{ENV.fetch("APP_HOST", "thomasinformationtechnology.com")}" : request.base_url
    "#{base}#{path}"
  end
end
