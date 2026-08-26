# A small in-code registry of the support plans we sell, matched to the
# Stripe Products/Prices created by `bin/rails stripe:setup_plans`. The
# actual charged amount always comes from Stripe's Price object, not from
# `display_price` here — that's just what we show on our own pages, and it's
# kept in sync manually when pricing changes in the Stripe dashboard.
class Plan
  Definition = Struct.new(:key, :name, :display_price, :tagline, :features, :price_id_env, keyword_init: true)

  ALL = [
    Definition.new(
      key: "basic", name: "Basic", display_price: "$49/mo",
      tagline: "For small teams that need a safety net",
      features: [ "Business-hours ticket support", "High priority: 24 hr response", "Low priority: 7 day response" ],
      price_id_env: "STRIPE_PRICE_BASIC"
    ),
    Definition.new(
      key: "business", name: "Business", display_price: "$149/mo",
      tagline: "Our most popular plan for growing teams",
      features: [ "Everything in Basic", "Medium priority: 3 day response", "Dedicated agent assignment" ],
      price_id_env: "STRIPE_PRICE_BUSINESS"
    ),
    Definition.new(
      key: "priority", name: "Priority", display_price: "$399/mo",
      tagline: "For teams where downtime isn't an option",
      features: [ "Everything in Business", "Critical priority: 4 hr response", "Escalation on missed SLA" ],
      price_id_env: "STRIPE_PRICE_PRIORITY"
    )
  ].freeze

  def self.find(key)
    ALL.find { |plan| plan.key == key.to_s }
  end

  def self.price_id_for(key)
    find(key)&.price_id_env&.then { |env_var| ENV[env_var] }
  end

  def self.key_for_price_id(price_id)
    ALL.find { |plan| ENV[plan.price_id_env] == price_id }&.key
  end
end
