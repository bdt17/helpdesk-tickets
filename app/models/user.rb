class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def agent?
    role == 1
  end

  def admin?
    role == 2
  end

  def active_for_authentication?
    super && (status != 0)
  end

  def inactive_message
    (status == 0) ? :account_disabled : super
  end
end
