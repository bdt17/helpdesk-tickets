class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # CORRECT Rails 8.1 enum syntax
  enum status: { inactive: 0, active: 1 }, _default: :active
  enum role: { customer: 0, agent: 1, admin: 2 }, _default: :customer

  def agent?
    role.in?(%w[agent admin])
  end

  def admin?
    role == 'admin'
  end

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

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :account_disabled
  end
end
