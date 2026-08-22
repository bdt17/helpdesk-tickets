namespace :users do
  desc "Create a user: rails users:create[email,password,role]"
  task :create, [ :email, :password, :role ] => :environment do |_t, args|
    email = args[:email]
    password = args[:password] || SecureRandom.hex(12)
    role = args[:role].presence || "employee"

    if email.blank?
      puts "Usage: rails users:create[email@thomasit.com,password,role]"
      puts "  role defaults to 'employee'; valid roles: #{User.roles.keys.join(', ')}"
      next
    end

    user = User.new(email: email, password: password, password_confirmation: password, role: role)
    if user.save
      puts "✅ Created #{user.email} (#{user.role})#{" - password: #{password}" unless args[:password]}"
    else
      puts "❌ Failed: #{user.errors.full_messages.join(', ')}"
    end
  end

  desc "Disable a user's account (blocks sign-in without deleting it)"
  task :disable, [ :email ] => :environment do |_t, args|
    user = User.find_by(email: args[:email])
    if user
      user.update!(status: :disabled)
      puts "🔒 DISABLED: #{user.email}"
    else
      puts "❌ User not found: #{args[:email]}"
    end
  end

  desc "Re-enable a disabled user's account"
  task :activate, [ :email ] => :environment do |_t, args|
    user = User.find_by(email: args[:email])
    if user
      user.update!(status: :active)
      puts "✅ ACTIVATED: #{user.email}"
    else
      puts "❌ User not found: #{args[:email]}"
    end
  end

  desc "Reset a user's password (active users only)"
  task :reset_password, [ :email ] => :environment do |_t, args|
    user = User.find_by(email: args[:email])
    if user&.active?
      new_pass = SecureRandom.hex(12)
      user.update!(password: new_pass, password_confirmation: new_pass)
      puts "✅ #{user.email} password reset: #{new_pass}"
    else
      puts "❌ User inactive/not found: #{args[:email]}"
    end
  end

  desc "List all users"
  task list: :environment do
    puts "👥 ALL USERS:"
    puts "=" * 60
    User.order(:email).find_each do |user|
      puts "#{user.email.ljust(30)} | #{user.status.ljust(10)} | #{user.role}"
    end
  end
end
