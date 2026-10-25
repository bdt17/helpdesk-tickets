require "test_helper"
require "ostruct"

class CancellationsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @owner = users(:client)
    @organization = Organization.create!(name: "Acme", stripe_customer_id: "cus_1", stripe_subscription_id: "sub_1",
                                         subscription_status: "active", plan: "business")
    @owner.update!(organization: @organization, org_role: "owner")
    sign_in @owner
  end

  test "the billing page links an owner to the cancel page" do
    get billing_url
    assert_select "a[href=?]", billing_cancel_path
  end

  test "cancel page shows reasons, the downgrade option, and the offer only when a coupon is configured" do
    get billing_cancel_url
    assert_response :success
    assert_select "input[type=radio][name=reason]", Organization::CANCELLATION_REASONS.size
    assert_select "form[action=?]", billing_portal_path
    assert_select "form[action=?]", billing_retention_offer_path, count: 0

    ENV["STRIPE_RETENTION_COUPON"] = "coupon_keep"
    get billing_cancel_url
    assert_select "form[action=?]", billing_retention_offer_path
  ensure
    ENV.delete("STRIPE_RETENTION_COUPON")
  end

  test "canceling schedules the end of the period, records the reason and tells staff" do
    ends = 20.days.from_now.change(usec: 0)
    captured = nil
    update = ->(id, params) { captured = [ id, params ]; OpenStruct.new(cancel_at: ends.to_i) }

    assert_enqueued_emails User.admin.count do
      Stripe::Subscription.stub(:update, update) do
        post billing_cancel_url, params: { reason: "too_expensive", comment: "Budget cuts" }
      end
    end

    assert_redirected_to billing_url
    assert_equal [ "sub_1", { cancel_at_period_end: true, cancellation_details: { feedback: "too_expensive", comment: "Budget cuts" } } ], captured
    @organization.reload
    assert_equal ends, @organization.cancel_at
    assert_equal "too_expensive", @organization.cancellation_reason
    assert @organization.canceling?
    assert_match "will end on", flash[:notice]

    follow_redirect!
    assert_select "form[action=?]", billing_resume_path
    assert_select "a[href=?]", billing_cancel_path, count: 0
  end

  test "a reason is required" do
    Stripe::Subscription.stub(:update, ->(*) { flunk "should not call Stripe" }) do
      post billing_cancel_url, params: { reason: "made-up" }
    end
    assert_redirected_to billing_cancel_url
    assert_nil @organization.reload.cancel_at
  end

  test "resuming clears the scheduled cancellation" do
    @organization.update!(cancel_at: 10.days.from_now)
    captured = nil
    Stripe::Subscription.stub(:update, ->(id, params) { captured = [ id, params ]; OpenStruct.new }) do
      post billing_resume_url
    end
    assert_equal [ "sub_1", { cancel_at_period_end: false } ], captured
    assert_nil @organization.reload.cancel_at
  end

  test "the retention offer applies the coupon once" do
    ENV["STRIPE_RETENTION_COUPON"] = "coupon_keep"
    calls = []
    Stripe::Subscription.stub(:update, ->(id, params) { calls << [ id, params ]; OpenStruct.new }) do
      post billing_retention_offer_url
      post billing_retention_offer_url
    end

    assert_equal [ [ "sub_1", { discounts: [ { coupon: "coupon_keep" } ] } ] ], calls
    assert @organization.reload.retention_offer_used_at
    assert_equal "That offer isn't available.", flash[:alert]
  ensure
    ENV.delete("STRIPE_RETENTION_COUPON")
  end

  test "a failed Stripe call gives the retention offer back" do
    ENV["STRIPE_RETENTION_COUPON"] = "coupon_keep"
    Stripe::Subscription.stub(:update, ->(*) { raise Stripe::APIConnectionError, "down" }) do
      post billing_retention_offer_url
    end
    assert_redirected_to billing_url
    assert_nil @organization.reload.retention_offer_used_at
  ensure
    ENV.delete("STRIPE_RETENTION_COUPON")
  end

  test "team members and unsubscribed clients can't cancel" do
    @owner.update!(org_role: "member")
    get billing_cancel_url
    assert_redirected_to billing_url

    @owner.update!(org_role: "owner")
    @organization.update!(subscription_status: "canceled")
    post billing_cancel_url, params: { reason: "unused" }
    assert_redirected_to billing_url
    assert_nil @organization.reload.cancel_at
  end

  test "staff cancellation emails render for every outcome" do
    @organization.update!(cancel_at: 5.days.from_now, cancellation_reason: "unused", cancellation_comment: "Quiet year")
    %w[canceled kept_with_discount resumed].each do |outcome|
      mail = BillingMailer.cancellation_staff_alert(@organization, users(:admin), outcome)
      assert_match "Acme", mail.subject
      assert_match @owner.email, mail.text_part.body.to_s
    end
    assert_match "Quiet year", BillingMailer.cancellation_staff_alert(@organization, users(:admin), "canceled").html_part.body.to_s
  end
end
