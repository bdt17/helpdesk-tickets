# The billing entity behind team/multi-seat plans (Phase 12): one paying
# Organization can hold several client User "seats" instead of the
# original one-user-one-subscription model. Subscription state here is
# synced from Stripe webhooks (see Webhooks::StripeController), same as
# it was on User before this existed - never set directly from user input.
class Organization < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :ticket_credit_purchases, dependent: :restrict_with_exception

  validates :name, presence: true

  # Shown on the cancel page. Keys are Stripe's own
  # cancellation_details.feedback values, so the reason is also recorded
  # on the subscription in the Stripe dashboard.
  CANCELLATION_REASONS = {
    "too_expensive" => "It's too expensive",
    "unused" => "We don't use it enough",
    "switched_service" => "We're switching to another provider",
    "missing_features" => "It's missing something we need",
    "customer_service" => "We weren't happy with the support",
    "other" => "Something else"
  }.freeze

  # Set (from Stripe) when the plan is scheduled to end - the client keeps
  # full support until then and can still change their mind.
  def canceling?
    cancel_at.present? && subscribed?
  end

  # The one-time "stay and get a discount" offer on the cancel page, when
  # a retention coupon is configured (see Plan.retention_coupon_id).
  def retention_offer_available?
    Plan.retention_coupon_id.present? && retention_offer_used_at.nil?
  end

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
