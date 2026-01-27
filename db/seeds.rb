User.create!(
  email: 'test@example.com',
  password: 'changeme123',
  password_confirmation: 'changeme123'
) unless Rails.env.test? && User.exists?(email: 'test@example.com')
