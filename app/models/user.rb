class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def agent?
    true  # All authenticated users = agents (simple)
  end

  def admin?
    false  # No admin checks needed yet
  end
end
