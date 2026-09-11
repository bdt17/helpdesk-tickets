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

  # The highest Ticket priority this user's own tickets may be set to (see
  # Ticket#priority_allowed_by_plan). Only client-role tickets are
  # plan-limited at all - internal tickets filed by staff/employees aren't
  # tied to a paid plan, so "critical" here just means "no cap". An
  # unsubscribed client (never paid, or lapsed) doesn't get the "high"
  # ceiling Basic itself has to be purchased to unlock.
  def max_ticket_priority
    return "critical" unless client?

    subscribed? ? (plan_definition&.max_priority || "medium") : "medium"
  end

  def org_owner?
    org_role == "owner"
  end

  def teammates
    return User.none unless organization

    organization.users.where.not(id: id)
  end
end
