class User < ApplicationRecord
  devise :two_factor_authenticatable
  devise :registerable,
         :recoverable, :rememberable, :validatable,
         :two_factor_authenticatable, :otp_encryptable,
         otp_secret_encryption_key: ENV['OTP_SECRET_ENCRYPTION_KEY']

  def agent?
    true  # All authenticated users = agents (simple)
  end

  def admin?
    false  # No admin checks needed yet
  end
end
