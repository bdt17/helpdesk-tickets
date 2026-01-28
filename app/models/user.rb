class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :status, [:inactive, :active], default: :active
  enum :role, [:customer, :agent, :admin], default: :customer

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :account_disabled
  end
end
