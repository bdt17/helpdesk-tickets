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

  test "checkout creates a Stripe customer once and redirects to the Checkout Session" do
    client = users(:client)
    sign_in client
    fake_customer = OpenStruct.new(id: "cus_123")
    fake_session = OpenStruct.new(url: "https://checkout.stripe.com/test-session")
    captured_args = nil

    Stripe::Customer.stub(:create, fake_customer) do
      Plan.stub(:price_id_for, "price_basic_test") do
        Stripe::Checkout::Session.stub(:create, ->(**kwargs) { captured_args = kwargs; fake_session }) do
          post billing_checkout_url(plan: "basic")
        end
      end
    end

    assert_redirected_to fake_session.url
    assert_equal "cus_123", client.reload.stripe_customer_id
    # Stripe rejects relative paths here (real API call, not just our own
    # routing) — assert absolute URLs so a `_path` vs `_url` helper mixup
    # like this controller once had can't slip through a mocked stub again.
    assert_match %r{\Ahttps?://}, captured_args[:success_url]
    assert_match %r{\Ahttps?://}, captured_args[:cancel_url]
  end

  test "checkout redirects back with an alert for an unknown plan" do
    sign_in users(:client)
    post billing_checkout_url(plan: "nonexistent")
    assert_redirected_to billing_url
    assert_equal "Unknown plan.", flash[:alert]
  end

  test "portal redirects to the Stripe billing portal for a known customer" do
    client = users(:client)
    client.update!(stripe_customer_id: "cus_123")
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
end
