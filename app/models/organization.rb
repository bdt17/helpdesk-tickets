# The billing entity behind team/multi-seat plans (Phase 12): one paying
# Organization can hold several client User "seats" instead of the
# original one-user-one-subscription model. Subscription state here is
# synced from Stripe webhooks (see Webhooks::StripeController), same as
# it was on User before this existed - never set directly from user input.
class Organization < ApplicationRecord
  has_many :users, dependent: :nullify

  validates :name, presence: true

  # past_due is Stripe's retry window after a declined card (it retries
  # for up to a couple of weeks, depending on the account's settings).
  # The client keeps full access during it - cutting off a paying client
  # the moment one charge bounces loses far more than it protects - and
  # sees a banner asking them to fix their card instead (see
  # #payment_problem?). Only when Stripe gives up (unpaid / canceled)
  # does access lapse.
  def subscribed?
    %w[active trialing past_due].include?(subscription_status)
  end

  # Set by the invoice.payment_failed webhook, cleared by invoice.paid.
  def payment_problem?
    payment_failed_at.present? || %w[past_due unpaid].include?(subscription_status)
  end

  def annual?
    billing_interval == "year"
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
