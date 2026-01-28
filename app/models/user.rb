class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def agent?
    role == 1 || role == '1'
  end

  def admin?
    role == 2 || role == '2'
  end

  def active_for_authentication?
    super && (role.present? && status.present?)
  end

  def inactive_message
    :account_disabled
  end
end
