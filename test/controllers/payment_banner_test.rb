require "test_helper"

class PaymentBannerTest < ActionDispatch::IntegrationTest
  setup do
    @org = Organization.create!(name: "Acme", stripe_customer_id: "cus_1", plan: "business",
                                subscription_status: "past_due", payment_failed_at: 1.hour.ago)
    @owner = users(:client)
    @owner.update!(organization: @org, org_role: "owner")
  end

  test "the owner sees the banner with an update-card button on every page" do
    sign_in @owner
    [ dashboard_url, tickets_url ].each do |url|
      get url
      assert_select ".alert-danger", text: /last payment didn't go through/
      assert_select "form[action=?] button", billing_portal_path, text: "Update payment method"
    end
  end

  test "a teammate is told to ask the owner instead" do
    member = User.create!(email: "member-banner@example.com", password: "password1234", role: :client, organization: @org, org_role: "member")
    sign_in member
    get dashboard_url
    assert_select ".alert-danger", text: /ask your account owner \(#{Regexp.escape(@owner.email)}\)/
    assert_select "form[action=?]", billing_portal_path, count: 0
  end

  test "after Stripe gives up, the owner is pointed at choosing a plan again" do
    @org.update!(subscription_status: "canceled")
    sign_in @owner
    get dashboard_url
    assert_select ".alert-danger", text: /plan was canceled/
    assert_select ".alert-danger a[href=?]", billing_path, text: "Choose a plan"
  end

  test "no banner once the invoice is paid, and never for staff" do
    @org.update!(subscription_status: "active", payment_failed_at: nil)
    sign_in @owner
    get dashboard_url
    assert_select ".alert-danger", count: 0

    sign_out :user
    sign_in users(:agent)
    get dashboard_url
    assert_select ".alert-danger", count: 0
  end

  test "admins see the organization in the payment-problems list on reports" do
    sign_in users(:admin)
    get reports_index_url
    assert_select ".card.border-danger td", text: "Acme"
  end
end
