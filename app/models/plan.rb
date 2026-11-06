# A small in-code registry of the support plans we sell, matched to the
# Stripe Products/Prices created by `bin/rails stripe:setup_plans`. The
# actual charged amount always comes from Stripe's Price object, not from
# `display_price` here — that's just what we show on our own pages, and it's
# kept in sync manually when pricing changes in the Stripe dashboard.
class Plan
  # max_priority is the highest Ticket priority this plan's tickets may be
  # set to (see Ticket#priority_allowed_by_plan) — the code-enforced side
  # of what each tier's `features` copy promises. Only Priority's copy
  # names "Critical priority" at all, so that's the only tier that unlocks
  # it; Basic and Business share the same "up to High" ceiling since
  # Business's copy only adds a Medium commitment on top of Basic's,
  # never mentioning Critical.
  #
  # max_seats is the enforced side of team billing (see
  # Organization#max_seats / TeamController#create): before this, an
  # organization on any plan could invite unlimited teammates for the
  # same price, which given this business's recurring-plans direction is
  # a real revenue gap, the same shape as the priority one was. THE
  # NUMBERS BELOW ARE PLACEHOLDERS, same status as display_price - picked
  # to be directionally reasonable (a small safety-net plan needs fewer
  # seats than a "for growing teams" one) but not an actual pricing
  # decision. Revisit before relying on them.
  #
  # monthly_ticket_limit is the ticket-volume side of the same recurring
  # plans model (nil = unlimited), counted per organization per calendar
  # month (see User#monthly_ticket_limit). Also PLACEHOLDERS - same status
  # as the prices and seat counts above.
  Definition = Struct.new(:key, :name, :display_price, :tagline, :features, :price_id_env, :max_priority, :max_seats, :monthly_ticket_limit, keyword_init: true)

  ALL = [
    Definition.new(
      key: "basic", name: "Basic", display_price: "$49/mo",
      tagline: "For small teams that need a safety net",
      features: [ "Business-hours ticket support", "High priority: 24 hr response", "Low priority: 7 day response" ],
      price_id_env: "STRIPE_PRICE_BASIC", max_priority: "high", max_seats: 3, monthly_ticket_limit: 10
    ),
    Definition.new(
      key: "business", name: "Business", display_price: "$149/mo",
      tagline: "Our most popular plan for growing teams",
      features: [ "Everything in Basic", "Medium priority: 3 day response", "Dedicated agent assignment" ],
      price_id_env: "STRIPE_PRICE_BUSINESS", max_priority: "high", max_seats: 10, monthly_ticket_limit: 40
    ),
    Definition.new(
      key: "priority", name: "Priority", display_price: "$399/mo",
      tagline: "For teams where downtime isn't an option",
      features: [ "Everything in Business", "Critical priority: 4 hr response", "Escalation on missed SLA" ],
      price_id_env: "STRIPE_PRICE_PRIORITY", max_priority: "critical", max_seats: 25, monthly_ticket_limit: nil
    )
  ].freeze

  # Stripe coupon offered once to a client who starts canceling (see
  # CancellationsController). Created by `bin/rails
  # stripe:setup_retention_coupon`; unset = no offer, straight to cancel.
  RETENTION_OFFER = "50% off your next 2 months".freeze

  def self.retention_coupon_id
    ENV["STRIPE_RETENTION_COUPON"].presence
  end

  # Estimated monthly revenue from one subscription on this plan; annual
  # subscriptions count at their monthly equivalent (yearly price / 12).
  def self.monthly_revenue(plan_key, interval)
    plan = find(plan_key)
    return 0 unless plan

    interval == "year" ? annual_dollars(plan) / 12.0 : monthly_dollars(plan)
  end

  # Whole dollars per month parsed from display_price, for the admin
  # revenue estimate on /reports. An estimate only - Stripe's Price (and
  # any coupon/trial) is what's actually charged.
  def self.monthly_dollars(plan)
    plan.display_price.to_s[/\d[\d,]*/].to_s.delete(",").to_i
  end

  # How many tickets a client who hasn't subscribed (never paid, or
  # lapsed) may file per calendar month - a free taste of the service
  # that leads into a plan, rather than unlimited free support. Tunable
  # from Render's environment without a deploy.
  def self.free_tickets_per_month
    ENV.fetch("FREE_TICKETS_PER_MONTH", 1).to_i
  end

  # Shown on pricing cards next to the seat count.
  def self.ticket_allowance_label(limit)
    limit ? "Up to #{limit} tickets/month" : "Unlimited tickets"
  end

  # Annual billing: a separate yearly Stripe Price per plan, priced at
  # ANNUAL_MONTHS_CHARGED x the monthly price ("2 months free"). Optional -
  # until STRIPE_PRICE_<PLAN>_ANNUAL is set (see `bin/rails
  # stripe:setup_annual_prices`), the billing page simply doesn't offer it.
  ANNUAL_MONTHS_CHARGED = 10

  def self.annual_price_env(key)
    find(key)&.price_id_env&.then { |env_var| "#{env_var}_ANNUAL" }
  end

  def self.annual_price_id_for(key)
    annual_price_env(key)&.then { |env_var| ENV[env_var].presence }
  end

  def self.annual_dollars(plan)
    monthly_dollars(plan) * ANNUAL_MONTHS_CHARGED
  end

  def self.annual_billing_available?
    ALL.any? { |plan| annual_price_id_for(plan.key) }
  end

  # "year" or "month" for one of our configured Price ids, nil if unknown.
  def self.interval_for_price_id(price_id)
    return nil if price_id.blank?
    return "year" if ALL.any? { |plan| annual_price_id_for(plan.key) == price_id }

    "month" if ALL.any? { |plan| ENV[plan.price_id_env] == price_id }
  end

  # One-off extra tickets for when a client has used their monthly
  # allowance (or free tier): EXTRA_TICKET_PRICE_CENTS each, charged via a
  # one-time Stripe Checkout with inline pricing, so there's nothing to
  # create in the Stripe dashboard first. Set it to 0 to turn the add-on
  # off. The default is a PLACEHOLDER like every other price here.
  MAX_EXTRA_TICKETS_PER_PURCHASE = 10

  def self.extra_ticket_price_cents
    ENV.fetch("EXTRA_TICKET_PRICE_CENTS", 3900).to_i
  end

  def self.extra_tickets_enabled?
    extra_ticket_price_cents.positive?
  end

  def self.find(key)
    ALL.find { |plan| plan.key == key.to_s }
  end

  def self.price_id_for(key)
    find(key)&.price_id_env&.then { |env_var| ENV[env_var] }
  end

  def self.key_for_price_id(price_id)
    return nil if price_id.blank?

    ALL.find { |plan| ENV[plan.price_id_env] == price_id || annual_price_id_for(plan.key) == price_id }&.key
  end
end
