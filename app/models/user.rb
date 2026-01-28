class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum status: { inactive: 0, active: 1 }, _default: :active
  enum role: { customer: 0, agent: 1, admin: 2 }, _default: :customer

  def agent?
    role.in?(%w[agent admin])
  end

  def admin?
    role == 'admin'
  end

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :account_disabled
  end
end
