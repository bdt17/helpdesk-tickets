class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # SAFE role/status checks - no crashes
  def agent?
    role.present? && (role.to_i == 1)
  end

  def admin?
    role.present? && (role.to_i == 2)
  end

  def active_for_authentication?
    super
  end

  def inactive_message
    super
  end
end
