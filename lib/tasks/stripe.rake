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
end
