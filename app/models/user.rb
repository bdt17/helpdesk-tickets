class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end

# Add these methods to your User model
def generate_password_reset_token!
  self.password_reset_token = SecureRandom.hex(16)
  self.password_reset_sent_at = Time.current
  save!
end

def clear_password_reset_token!
  self.password_reset_token = nil
  self.password_reset_sent_at = nil
  save!
end

def password_reset_expired?
  password_reset_sent_at < 2.hours.ago
end
