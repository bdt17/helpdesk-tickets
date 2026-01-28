class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # FIXED ENUM SYNTAX for Rails 8.1
  enum :role, { customer: 0, agent: 1, admin: 2 }, default: 0
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { customer: 0, agent: 1, admin: 2 }, default: 0

  # ADD THESE TWO METHODS - critical!
  def agent?
    role == 'agent' || role == 'admin'
  end

  def admin?
    role == 'admin'
  end

  # ... your existing password methods ...
end


  # Role helpers
  def agent?
    role.in?(%w[agent admin])
  end

  def admin?
    role == 'admin'
  end

  # Keep ALL your existing password methods below...
  def generate_password_reset_token!
    # ... your existing code
  end
  # ... rest unchanged
end
