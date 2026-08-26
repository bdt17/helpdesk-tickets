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

    test "checkout.session.completed activates the client's plan" do
      client = users(:client)
      client.update!(stripe_customer_id: "cus_123")

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
      client.reload
      assert_equal "sub_123", client.stripe_subscription_id
      assert_equal "active", client.subscription_status
      assert_equal "business", client.plan
      assert client.subscribed?
    end

    test "customer.subscription.deleted marks the client as no longer subscribed" do
      client = users(:client)
      client.update!(stripe_customer_id: "cus_123", plan: "business", subscription_status: "active")

      ENV["STRIPE_PRICE_BUSINESS"] = "price_business_test"
      fake_subscription = fake_subscription(customer: "cus_123", status: "canceled", price_id: "price_business_test")
      event = OpenStruct.new(type: "customer.subscription.deleted", data: OpenStruct.new(object: fake_subscription))

      Stripe::Webhook.stub(:construct_event, event) do
        post webhooks_stripe_url, params: "{}", headers: { "Stripe-Signature" => "valid" }
      end

      assert_response :ok
      client.reload
      assert_equal "canceled", client.subscription_status
      assert_not client.subscribed?
    end

    test "ignores events for a customer we don't recognize" do
      fake_subscription = fake_subscription(customer: "cus_unknown", status: "active", price_id: "price_business_test")
      event = OpenStruct.new(type: "customer.subscription.updated", data: OpenStruct.new(object: fake_subscription))

      assert_no_difference("User.where(subscription_status: 'active').count") do
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
