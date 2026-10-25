namespace :stripe do
  desc "Create the Basic/Business/Priority Products+Prices in Stripe from Plan::ALL and print the env vars to set"
  task setup_plans: :environment do
    abort "STRIPE_SECRET_KEY is not set" if ENV["STRIPE_SECRET_KEY"].blank?

    Plan::ALL.each do |plan|
      product = Stripe::Product.create(name: "Thomas IT Helpdesk — #{plan.name} Plan")
      amount_cents = plan.display_price[/\d+/].to_i * 100
      price = Stripe::Price.create(
        product: product.id,
        unit_amount: amount_cents,
        currency: "usd",
        recurring: { interval: "month" }
      )
      puts "#{plan.price_id_env}=#{price.id}"
    end

    puts "\nAdd the lines above to your .env (development) and to your Render environment variables (production)."
  end

  desc "Add a yearly Price (10x monthly) to each plan's existing Stripe Product and print the env vars to set"
  task setup_annual_prices: :environment do
    abort "STRIPE_SECRET_KEY is not set" if ENV["STRIPE_SECRET_KEY"].blank?

    Plan::ALL.each do |plan|
      monthly_price_id = Plan.price_id_for(plan.key)
      abort "#{plan.price_id_env} is not set - run stripe:setup_plans first" if monthly_price_id.blank?

      # Same Product as the monthly price, so Stripe's billing portal can
      # switch a client between monthly and yearly on one plan.
      product_id = Stripe::Price.retrieve(monthly_price_id).product
      price = Stripe::Price.create(
        product: product_id,
        unit_amount: Plan.annual_dollars(plan) * 100,
        currency: "usd",
        recurring: { interval: "year" }
      )
      puts "#{Plan.annual_price_env(plan.key)}=#{price.id}"
    end

    puts "\nAdd the lines above to your .env (development) and to your Render environment variables (production)."
  end

  desc "Create the 50%-off-for-2-months coupon offered on the cancel page and print the env var to set"
  task setup_retention_coupon: :environment do
    abort "STRIPE_SECRET_KEY is not set" if ENV["STRIPE_SECRET_KEY"].blank?

    # Must match Plan::RETENTION_OFFER, which is what the cancel page says.
    coupon = Stripe::Coupon.create(name: "Stay with us - 50% off 2 months", percent_off: 50, duration: "repeating", duration_in_months: 2)
    puts "STRIPE_RETENTION_COUPON=#{coupon.id}"
    puts "\nAdd the line above to your Render environment variables."
  end
end
