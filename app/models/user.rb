class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :lockable, :registerable

  enum :role, { employee: "employee", agent: "agent", admin: "admin", client: "client" }, default: :employee
  enum :status, { disabled: 0, active: 1 }, default: :active

  # Only meaningful for client-role users: which seat they hold in their
  # Organization's subscription (Phase 12, matches the plain-string +
  # inclusion-validation pattern Ticket::CATEGORIES already uses, rather
  # than another enum). Every other role has no organization at all.
  ORG_ROLES = %w[owner member].freeze
  validates :org_role, inclusion: { in: ORG_ROLES }, allow_nil: true

  belongs_to :organization, optional: true
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

  # Billing lives on Organization, not User (Phase 12) - a client with no
  # organization yet (never subscribed) is simply not subscribed.
  def subscribed?
    organization&.subscribed? || false
  end

  def plan_definition
    organization&.plan_definition
  end

  def org_owner?
    org_role == "owner"
  end

  def teammates
    return User.none unless organization

    organization.users.where.not(id: id)
  end
end
