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

    test "a paid extra-tickets checkout credits the organization exactly once" do
      organization = Organization.create!(name: "Acme", stripe_customer_id: "cus_123")
      event = extra_tickets_event(organization)

      post_event event
      assert_response :ok
      assert_equal 3, organization.reload.extra_ticket_credits
      assert_equal 11700, organization.ticket_credit_purchases.sum(:amount_cents)

      post_event event # Stripe redelivers
      assert_equal 3, organization.reload.extra_ticket_credits
      assert_equal 1, organization.ticket_credit_purchases.count
    end

    test "extra-tickets metadata pointing at another customer's organization is ignored" do
      victim = Organization.create!(name: "Victim", stripe_customer_id: "cus_victim")
      post_event extra_tickets_event(victim, customer: "cus_attacker")
      assert_equal 0, victim.reload.extra_ticket_credits
    end

    test "an unpaid extra-tickets checkout grants nothing" do
      organization = Organization.create!(name: "Acme", stripe_customer_id: "cus_123")
      post_event extra_tickets_event(organization, payment_status: "unpaid")
      assert_equal 0, organization.reload.extra_ticket_credits
    end

    test "a yearly subscription is recorded as annual" do
      organization = Organization.create!(name: "Acme", stripe_customer_id: "cus_123")
      ENV["STRIPE_PRICE_BUSINESS_ANNUAL"] = "price_business_year"
      event = OpenStruct.new(type: "customer.subscription.updated",
                             data: OpenStruct.new(object: fake_subscription(customer: "cus_123", status: "active", price_id: "price_business_year")))
      post_event event

      organization.reload
      assert_equal "business", organization.plan
      assert organization.annual?
    ensure
      ENV.delete("STRIPE_PRICE_BUSINESS_ANNUAL")
    end

    test "invoice.payment_failed records the failure and emails the owner and admins" do
      organization = Organization.create!(name: "Acme", stripe_customer_id: "cus_123", plan: "business", subscription_status: "active")
      users(:client).update!(organization: organization, org_role: "owner")

      assert_enqueued_emails 1 + User.admin.count do
        post_event payment_failed_event("evt_fail_1")
      end

      assert_response :ok
      assert organization.reload.payment_failed_at.present?
      assert organization.payment_problem?
      assert_equal "evt_fail_1", organization.last_payment_failure_event_id
    end

    test "a redelivered payment_failed event doesn't email twice" do
      organization = Organization.create!(name: "Acme", stripe_customer_id: "cus_123", plan: "business", subscription_status: "active")
      users(:client).update!(organization: organization, org_role: "owner")
      post_event payment_failed_event("evt_fail_1")

      assert_no_enqueued_emails do
        post_event payment_failed_event("evt_fail_1")
      end
      assert_response :ok
    end

    test "a later failed retry is a new event and does notify again" do
      organization = Organization.create!(name: "Acme", stripe_customer_id: "cus_123", plan: "business", subscription_status: "past_due")
      users(:client).update!(organization: organization, org_role: "owner")
      post_event payment_failed_event("evt_fail_1")

      assert_enqueued_emails 1 + User.admin.count do
        post_event payment_failed_event("evt_fail_2")
      end
    end

    test "payment_failed for an unknown customer is ignored" do
      assert_no_enqueued_emails do
        post_event payment_failed_event("evt_x", customer: "cus_unknown")
      end
      assert_response :ok
    end

    test "invoice.paid clears a recorded payment failure" do
      organization = Organization.create!(name: "Acme", stripe_customer_id: "cus_123", plan: "business",
                                          subscription_status: "active", payment_failed_at: 1.day.ago)
      post_event OpenStruct.new(id: "evt_paid", type: "invoice.paid", data: OpenStruct.new(object: OpenStruct.new(customer: "cus_123")))

      assert_response :ok
      assert_nil organization.reload.payment_failed_at
      assert_not organization.payment_problem?
    end

    private

    include ActionMailer::TestHelper

    def post_event(event)
      Stripe::Webhook.stub(:construct_event, event) do
        post webhooks_stripe_url, params: "{}", headers: { "Stripe-Signature" => "valid" }
      end
    end

    def extra_tickets_event(organization, customer: organization.stripe_customer_id, payment_status: "paid")
      session = OpenStruct.new(id: "cs_extra_1", mode: "payment", customer: customer, payment_status: payment_status,
                               amount_total: 11700, subscription: nil,
                               metadata: { "kind" => "extra_tickets", "organization_id" => organization.id.to_s, "quantity" => "3" })
      OpenStruct.new(id: "evt_cs_1", type: "checkout.session.completed", data: OpenStruct.new(object: session))
    end

    def payment_failed_event(id, customer: "cus_123")
      invoice = OpenStruct.new(customer: customer, amount_due: 14900, currency: "usd", attempt_count: 1,
                               next_payment_attempt: 3.days.from_now.to_i, hosted_invoice_url: "https://invoice.stripe.com/i/test")
      OpenStruct.new(id: id, type: "invoice.payment_failed", data: OpenStruct.new(object: invoice))
    end

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
