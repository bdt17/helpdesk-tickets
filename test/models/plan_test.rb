require "test_helper"

class PlanTest < ActiveSupport::TestCase
  setup do
    @saved = ENV.to_h.slice("STRIPE_PRICE_BASIC", "STRIPE_PRICE_BASIC_ANNUAL")
    ENV["STRIPE_PRICE_BASIC"] = "price_basic_month"
    ENV["STRIPE_PRICE_BASIC_ANNUAL"] = "price_basic_year"
  end

  teardown do
    %w[STRIPE_PRICE_BASIC STRIPE_PRICE_BASIC_ANNUAL].each { |k| @saved.key?(k) ? ENV[k] = @saved[k] : ENV.delete(k) }
  end

  test "annual price is 10x monthly (2 months free)" do
    assert_equal 490, Plan.annual_dollars(Plan.find("basic"))
  end

  test "both monthly and annual price ids map back to the plan, with their interval" do
    assert_equal "basic", Plan.key_for_price_id("price_basic_month")
    assert_equal "basic", Plan.key_for_price_id("price_basic_year")
    assert_equal "month", Plan.interval_for_price_id("price_basic_month")
    assert_equal "year", Plan.interval_for_price_id("price_basic_year")
    assert_nil Plan.interval_for_price_id("price_unknown")
    assert_nil Plan.key_for_price_id(nil)
  end

  test "annual billing is only offered once an annual price is configured" do
    assert Plan.annual_billing_available?
    ENV.delete("STRIPE_PRICE_BASIC_ANNUAL")
    assert_nil Plan.annual_price_id_for("basic")
  end
end
