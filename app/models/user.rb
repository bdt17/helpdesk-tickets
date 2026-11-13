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
  # Deleting a technician removes their logged time too (disable them
  # instead to keep it - see Admin::UsersController).
  has_many :time_entries, dependent: :destroy

  # Devise calls this to decide whether a disabled account may authenticate,
  # independent of the lockable failed-attempts lock.
  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :account_disabled
  end

  # Team invites reuse Devise's reset-password token as the "set your
  # password" link, but the normal 6-hour reset window is far too short for
  # an invite someone may not open until tomorrow.
  INVITE_LINK_VALIDITY = 7.days

  def send_team_invite(inviter)
    update!(invitation_pending: true)
    raw_token = send(:set_reset_password_token)
    UserMailer.team_invite(self, inviter, raw_token).deliver_later
  end

  def reset_password_period_valid?
    return super unless invitation_pending?

    reset_password_sent_at.present? && reset_password_sent_at.utc >= INVITE_LINK_VALIDITY.ago.utc
  end

  # Setting a password through the link accepts the invite.
  def reset_password(new_password, new_password_confirmation)
    self.invitation_pending = false if new_password.present?
    super
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

  # Ticket volume allowed per calendar month (Plan#monthly_ticket_limit),
  # shared across the whole organization the same way seats are. nil means
  # unlimited - every non-client role, and plans with no cap.
  def monthly_ticket_limit
    return nil unless client?

    subscribed? ? plan_definition&.monthly_ticket_limit : Plan.free_tickets_per_month
  end

  def tickets_filed_this_month
    filers = organization ? organization.users : User.where(id: id)
    Ticket.where(user: filers).where(created_at: Time.current.beginning_of_month..).count
  end

  # Past the monthly allowance - from here each new ticket needs one of
  # the organization's purchased extra-ticket credits.
  def over_ticket_allowance?
    limit = monthly_ticket_limit
    limit.present? && tickets_filed_this_month >= limit
  end

  def extra_ticket_credits
    organization&.extra_ticket_credits.to_i
  end

  def ticket_limit_reached?
    over_ticket_allowance? && extra_ticket_credits <= 0
  end

  def org_owner?
    org_role == "owner"
  end

  def teammates
    return User.none unless organization

    organization.users.where.not(id: id)
  end
end
