# The billing entity behind team/multi-seat plans (Phase 12): one paying
# Organization can hold several client User "seats" instead of the
# original one-user-one-subscription model. Subscription state here is
# synced from Stripe webhooks (see Webhooks::StripeController), same as
# it was on User before this existed - never set directly from user input.
class Organization < ApplicationRecord
  has_many :users, dependent: :nullify

  validates :name, presence: true

  def subscribed?
    %w[active trialing].include?(subscription_status)
  end

  def plan_definition
    Plan.find(plan)
  end

  def owner
    users.find_by(org_role: "owner")
  end

  def members
    users.where.not(org_role: "owner")
  end

  # An unsubscribed organization (never paid, or lapsed) is capped at 1 -
  # just the owner, no invited seats - the same floor
  # User#max_ticket_priority uses: a plan actually has to be bought to
  # unlock anything beyond the bare minimum.
  def max_seats
    subscribed? ? (plan_definition&.max_seats || 1) : 1
  end

  def seats_used
    users.count
  end

  def seats_available?
    seats_used < max_seats
  end
end
