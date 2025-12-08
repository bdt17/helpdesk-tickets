config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: 'smtp.gmail.com',
  port: 587,
  domain: 'gmail.com',
  user_name: 'brett.thomas29.97@gmail.com',
  password: ENV['SMTP_PASSWORD'],
  authentication: 'login',
  enable_starttls_auto: true
}
config.action_mailer.default_url_options = { host: 'helpdesk-tickets-yfpr.onrender.com' }
