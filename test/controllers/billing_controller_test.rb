require "test_helper"
require "ostruct"

class BillingControllerTest < ActionDispatch::IntegrationTest
  test "redirects to sign in when unauthenticated" do
    get billing_url
    assert_redirected_to new_user_session_url
  end

  test "non-client roles cannot access billing" do
    sign_in users(:employee)
    get billing_url
    assert_redirected_to root_url
    assert_equal "Billing is only available for client accounts.", flash[:alert]
  end

  test "client sees the plans page" do
    sign_in users(:client)
    get billing_url
    assert_response :success
    assert_includes @response.body, "Basic"
    assert_includes @response.body, "Business"
    assert_includes @response.body, "Priority"
  end

  test "checkout creates an organization (owned by the client) and a Stripe customer on first subscribe" do
    client = users(:client)
    sign_in client
    fake_customer = OpenStruct.new(id: "cus_123")
    fake_session = OpenStruct.new(url: "https://checkout.stripe.com/test-session")
    captured_args = nil

    assert_difference "Organization.count", 1 do
      Stripe::Customer.stub(:create, fake_customer) do
        Plan.stub(:price_id_for, "price_basic_test") do
          Stripe::Checkout::Session.stub(:create, ->(**kwargs) { captured_args = kwargs; fake_session }) do
            post billing_checkout_url(plan: "basic")
          end
        end
      end
    end

    assert_redirected_to fake_session.url
    client.reload
    assert_equal "owner", client.org_role
    assert_equal "cus_123", client.organization.stripe_customer_id
    # Stripe rejects relative paths here (real API call, not just our own
    # routing) — assert absolute URLs so a `_path` vs `_url` helper mixup
    # like this controller once had can't slip through a mocked stub again.
    assert_match %r{\Ahttps?://}, captured_args[:success_url]
    assert_match %r{\Ahttps?://}, captured_args[:cancel_url]
  end

  test "checkout reuses the existing organization and customer on a later subscribe" do
    client = users(:client)
    organization = Organization.create!(name: "Existing Org", stripe_customer_id: "cus_existing")
    client.update!(organization: organization, org_role: "owner")
    sign_in client
    fake_session = OpenStruct.new(url: "https://checkout.stripe.com/test-session")

    assert_no_difference "Organization.count" do
      Plan.stub(:price_id_for, "price_basic_test") do
        Stripe::Checkout::Session.stub(:create, fake_session) do
          post billing_checkout_url(plan: "basic")
        end
      end
    end

    assert_redirected_to fake_session.url
  end

  test "a team member (not the owner) cannot start a checkout" do
    organization = Organization.create!(name: "Existing Org", stripe_customer_id: "cus_existing")
    client = users(:client)
    client.update!(organization: organization, org_role: "member")
    sign_in client

    Plan.stub(:price_id_for, "price_basic_test") do
      post billing_checkout_url(plan: "basic")
    end

    assert_redirected_to billing_url
    assert_equal "Only the account owner can change plans.", flash[:alert]
  end

  test "checkout redirects back with an alert for an unknown plan" do
    sign_in users(:client)
    post billing_checkout_url(plan: "nonexistent")
    assert_redirected_to billing_url
    assert_equal "Unknown plan.", flash[:alert]
  end

  test "portal redirects to the Stripe billing portal for the organization owner" do
    client = users(:client)
    organization = Organization.create!(name: "Org", stripe_customer_id: "cus_123")
    client.update!(organization: organization, org_role: "owner")
    sign_in client
    fake_session = OpenStruct.new(url: "https://billing.stripe.com/test-portal")

    Stripe::BillingPortal::Session.stub(:create, fake_session) do
      post billing_portal_url
    end

    assert_redirected_to fake_session.url
  end

  test "portal redirects with an alert when there's no Stripe customer yet" do
    sign_in users(:client)
    post billing_portal_url
    assert_redirected_to billing_url
    assert_equal "No billing account on file yet.", flash[:alert]
  end

  test "a team member cannot open the billing portal" do
    organization = Organization.create!(name: "Org", stripe_customer_id: "cus_123")
    client = users(:client)
    client.update!(organization: organization, org_role: "member")
    sign_in client

    post billing_portal_url

    assert_redirected_to billing_url
    assert_equal "Only the account owner can manage billing.", flash[:alert]
  end

  test "a Stripe failure shows a generic alert, not Stripe's own error text" do
    client = users(:client)
    organization = Organization.create!(name: "Existing Org", stripe_customer_id: "cus_existing")
    client.update!(organization: organization, org_role: "owner")
    sign_in client
    failing = ->(**) { raise Stripe::InvalidRequestError.new("No such price: price_secret_internal_id", "price") }

    Plan.stub(:price_id_for, "price_basic_test") do
      Stripe::Checkout::Session.stub(:create, failing) do
        post billing_checkout_url(plan: "basic")
      end
    end

    assert_redirected_to billing_url
    assert_equal "Couldn't start checkout. Please try again or contact support.", flash[:alert]
    assert_no_match(/price_secret_internal_id/, flash[:alert])
  end

  test "checkout allows promotion codes, and adds a trial only when STRIPE_TRIAL_DAYS is set" do
    client = users(:client)
    organization = Organization.create!(name: "Existing Org", stripe_customer_id: "cus_existing")
    client.update!(organization: organization, org_role: "owner")
    sign_in client
    captured = []
    fake_session = OpenStruct.new(url: "https://checkout.stripe.com/test-session")
    capture = ->(**kwargs) { captured << kwargs; fake_session }

    Plan.stub(:price_id_for, "price_basic_test") do
      Stripe::Checkout::Session.stub(:create, capture) do
        post billing_checkout_url(plan: "basic")
        ENV["STRIPE_TRIAL_DAYS"] = "14"
        post billing_checkout_url(plan: "basic")
      end
    end

    assert_equal true, captured[0][:allow_promotion_codes]
    assert_nil captured[0][:subscription_data]
    assert_equal({ trial_period_days: 14 }, captured[1][:subscription_data])
  ensure
    ENV.delete("STRIPE_TRIAL_DAYS")
  end

  test "yearly checkout uses the plan's annual price" do
    client = users(:client)
    client.update!(organization: Organization.create!(name: "Org", stripe_customer_id: "cus_existing"), org_role: "owner")
    sign_in client
    captured = nil
    ENV["STRIPE_PRICE_BASIC_ANNUAL"] = "price_basic_year"

    Stripe::Checkout::Session.stub(:create, ->(**kw) { captured = kw; OpenStruct.new(url: "https://checkout.stripe.com/y") }) do
      post billing_checkout_url(plan: "basic", interval: "year")
    end

    assert_redirected_to "https://checkout.stripe.com/y"
    assert_equal [ { price: "price_basic_year", quantity: 1 } ], captured[:line_items]
  ensure
    ENV.delete("STRIPE_PRICE_BASIC_ANNUAL")
  end

  test "yearly checkout without an annual price configured is refused" do
    sign_in users(:client)
    ENV.delete("STRIPE_PRICE_BASIC_ANNUAL")
    Plan.stub(:price_id_for, "price_basic_month") do
      post billing_checkout_url(plan: "basic", interval: "year")
    end
    assert_redirected_to billing_url
    assert_equal "Unknown plan.", flash[:alert]
  end

  test "the billing page offers yearly only for plans with an annual price" do
    sign_in users(:client)
    ENV["STRIPE_PRICE_BASIC_ANNUAL"] = "price_basic_year"
    get billing_url
    assert_select "form[action=?]", billing_checkout_path(plan: "basic", interval: "year")
    assert_select "form[action=?]", billing_checkout_path(plan: "business", interval: "year"), count: 0
    assert_match "$490/yr", response.body
  ensure
    ENV.delete("STRIPE_PRICE_BASIC_ANNUAL")
  end
end
