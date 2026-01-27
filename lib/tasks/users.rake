namespace :users do
  desc "DISABLE all clear-text password accounts"
  task :secure_all => :environment do
    # DISABLE accounts with 2026! passwords
    disabled = User.where("encrypted_password LIKE ?", '%2026!%').update_all(active: false)
    puts "🔒 #{disabled} accounts with clear-text 2026! passwords DISABLED"
    
    # List all users status
    puts "\n👥 USER STATUS:"
    puts "=" * 60
    User.find_each do |user|
      status = user.active? ? "ACTIVE" : "DISABLED"
      puts "#{user.email.ljust(30)} | #{status} | #{user.role || 'user'}"
    end
  end
  
  desc "Create test users (DISABLED by default)"
  task :create_test_users => :environment do
    users = [
      {email: 'test@example.com', password: SecureRandom.hex(12), role: 'user'},
      {email: 'admin@thomasit.com', password: SecureRandom.hex(12), role: 'admin'},
      {email: 'driver@thomasit.com', password: SecureRandom.hex(12), role: 'driver'}
    ]
    
    users.each do |data|
      user = User.find_or_initialize_by(email: data[:email])
      user.update!(
        password: data[:password],
        password_confirmation: data[:password],
        role: data[:role],
        active: false  # DISABLED by default
      )
      puts "👤 #{user.email} (#{user.role}) - DISABLED - Password: #{data[:password]}"
    end
  end
  
  desc "ACTIVATE specific user"
  task :activate, [:email] => :environment do |t, args|
    user = User.find_by(email: args[:email])
    if user
      user.update!(active: true)
      puts "✅ ACTIVATED: #{user.email}"
    else
      puts "❌ User not found: #{args[:email]}"
    end
  end
  
  desc "RESET password (ACTIVE users only)"
  task :reset_password, [:email] => :environment do |t, args|
    user = User.find_by(email: args[:email])
    if user&.active?
      new_pass = SecureRandom.hex(12)
      user.update!(
        password: new_pass,
        password_confirmation: new_pass
      )
      puts "✅ #{user.email} password reset: #{new_pass}"
    else
      puts "❌ User inactive/not found: #{args[:email]}"
    end
  end
  
  desc "List all users"
  task :list => :environment do
    puts "👥 ALL USERS:"
    puts "=" * 60
    User.order(:email).find_each do |user|
      status = user.active? ? "ACTIVE" : "DISABLED"
      puts "#{user.email.ljust(30)} | #{status.ljust(10)} | #{user.role || 'user'}"
    end
  end
end
