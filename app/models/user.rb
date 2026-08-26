class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :lockable, :registerable

  enum :role, { employee: "employee", agent: "agent", admin: "admin", client: "client" }, default: :employee
  enum :status, { disabled: 0, active: 1 }, default: :active

  has_many :tickets, dependent: :nullify
  has_many :assigned_tickets, class_name: "Ticket", foreign_key: :assignee_id, dependent: :nullify
  has_many :comments, dependent: :destroy

  # Devise calls this to decide whether a disabled account may authenticate,
  # independent of the lockable failed-attempts lock.
  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :account_disabled
  end

  # Subscription state is synced from Stripe webhooks (see
  # Webhooks::StripeController), never set directly from user input.
  def subscribed?
    %w[active trialing].include?(subscription_status)
  end

  def plan_definition
    Plan.find(plan)
  end
end
