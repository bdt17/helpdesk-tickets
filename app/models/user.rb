class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :lockable

  enum :role, { employee: "employee", agent: "agent", admin: "admin" }, default: :employee
  enum :status, { disabled: 0, active: 1 }, default: :active

  has_many :tickets, dependent: :nullify

  # Devise calls this to decide whether a disabled account may authenticate,
  # independent of the lockable failed-attempts lock.
  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :account_disabled
  end
end
