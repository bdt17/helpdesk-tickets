class ApplicationMailer < ActionMailer::Base
  # Must be an address on a domain the SMTP provider has verified, or
  # mail gets rejected / spam-foldered. thomasit.com (the old hardcoded
  # value) isn't this business's domain.
  default from: ENV.fetch("MAIL_FROM", "support@thomasinformationtechnology.com")
  layout "mailer"
end
