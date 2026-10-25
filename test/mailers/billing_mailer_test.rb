require "test_helper"

class BillingMailerTest < ActionMailer::TestCase
  setup do
    @organization = Organization.create!(name: "Acme", stripe_customer_id: "cus_1", plan: "business", subscription_status: "past_due")
    users(:client).update!(organization: @organization, org_role: "owner")
    @details = { amount_due: 14900, currency: "usd", attempt_count: 2,
                 next_payment_attempt: Time.zone.local(2026, 11, 3, 12).to_i, hosted_invoice_url: "https://invoice.stripe.com/i/abc" }
  end

  test "payment_failed tells the owner how much, when the retry is, and how to fix it" do
    mail = BillingMailer.payment_failed(@organization, users(:client), @details)

    assert_equal [ users(:client).email ], mail.to
    assert_match "didn't go through", mail.subject
    [ mail.text_part.body.to_s, mail.html_part.body.to_s ].each do |body|
      assert_match "$149.00", body
      assert_match "November 3, 2026", body
      assert_match "/billing", body
      assert_match "https://invoice.stripe.com/i/abc", body
    end
  end

  test "payment_failed works without a retry date or hosted invoice" do
    mail = BillingMailer.payment_failed(@organization, users(:client), @details.merge(next_payment_attempt: nil, hosted_invoice_url: nil))
    assert_no_match "try again on", mail.text_part.body.to_s
    assert_no_match "pay this invoice", mail.text_part.body.to_s
  end

  test "staff alert names the organization, owner and amount" do
    mail = BillingMailer.payment_failed_staff_alert(@organization, users(:admin), @details)

    assert_equal [ users(:admin).email ], mail.to
    assert_equal "Payment failed: Acme ($149.00)", mail.subject
    assert_match users(:client).email, mail.text_part.body.to_s
    assert_match "Business", mail.text_part.body.to_s
  end
end
