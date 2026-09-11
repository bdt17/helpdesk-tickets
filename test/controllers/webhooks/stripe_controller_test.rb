require "test_helper"
require "ostruct"

module Webhooks
  class StripeControllerTest < ActionDispatch::IntegrationTest
    setup do
      @previous_secret = ENV["STRIPE_WEBHOOK_SECRET"]
      ENV["STRIPE_WEBHOOK_SECRET"] = "whsec_test"
    end

    teardown do
      ENV["STRIPE_WEBHOOK_SECRET"] = @previous_secret
    end

    test "rejects a request with a bad signature" do
      Stripe::Webhook.stub(:construct_event, ->(*) { raise Stripe::SignatureVerificationError.new("bad sig", "sig") }) do
        post webhooks_stripe_url, params: "{}", headers: { "Stripe-Signature" => "invalid" }
      end
      assert_response :bad_request
    end

    test "checkout.session.completed activates the organization's plan" do
      organization = Organization.create!(name: "Acme", stripe_customer_id: "cus_123")
      users(:client).update!(organization: organization, org_role: "owner")

      ENV["STRIPE_PRICE_BUSINESS"] = "price_business_test"
      fake_subscription = fake_subscription(customer: "cus_123", status: "active", price_id: "price_business_test")
      checkout_session = OpenStruct.new(subscription: "sub_123")
      event = OpenStruct.new(type: "checkout.session.completed", data: OpenStruct.new(object: checkout_session))

      Stripe::Webhook.stub(:construct_event, event) do
        Stripe::Subscription.stub(:retrieve, fake_subscription) do
          post webhooks_stripe_url, params: "{}", headers: { "Stripe-Signature" => "valid" }
        end
      end

      assert_response :ok
      organization.reload
      assert_equal "sub_123", organization.stripe_subscription_id
      assert_equal "active", organization.subscription_status
      assert_equal "business", organization.plan
      assert organization.subscribed?
      # Every seat on the organization shares the plan, not just whoever
      # happens to hold the Stripe customer record.
      assert users(:client).reload.subscribed?
    end

    test "customer.subscription.deleted marks the organization as no longer subscribed" do
      organization = Organization.create!(name: "Acme", stripe_customer_id: "cus_123", plan: "business", subscription_status: "active")
      users(:client).update!(organization: organization, org_role: "owner")

      ENV["STRIPE_PRICE_BUSINESS"] = "price_business_test"
      fake_subscription = fake_subscription(customer: "cus_123", status: "canceled", price_id: "price_business_test")
      event = OpenStruct.new(type: "customer.subscription.deleted", data: OpenStruct.new(object: fake_subscription))

      Stripe::Webhook.stub(:construct_event, event) do
        post webhooks_stripe_url, params: "{}", headers: { "Stripe-Signature" => "valid" }
      end

      assert_response :ok
      organization.reload
      assert_equal "canceled", organization.subscription_status
      assert_not organization.subscribed?
    end

    test "ignores events for a customer we don't recognize" do
      fake_subscription = fake_subscription(customer: "cus_unknown", status: "active", price_id: "price_business_test")
      event = OpenStruct.new(type: "customer.subscription.updated", data: OpenStruct.new(object: fake_subscription))

      assert_no_difference("Organization.where(subscription_status: 'active').count") do
        Stripe::Webhook.stub(:construct_event, event) do
          post webhooks_stripe_url, params: "{}", headers: { "Stripe-Signature" => "valid" }
        end
      end

      assert_response :ok
    end

    private

    def fake_subscription(customer:, status:, price_id:)
      OpenStruct.new(
        id: "sub_123",
        customer: customer,
        status: status,
        items: OpenStruct.new(data: [ OpenStruct.new(price: OpenStruct.new(id: price_id)) ])
      )
    end
  end
end
