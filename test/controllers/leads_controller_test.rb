require "test_helper"

class LeadsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup { Rails.cache.clear }

  def lead_params(overrides = {})
    { lead: { name: "Sam Buyer", email: "sam@buyer.example", company: "Buyer Co", message: "Need help" }.merge(overrides) }
  end

  test "the homepage has the contact form" do
    get root_url
    assert_select "form[action=?]", leads_path
  end

  test "anyone can submit the contact form; it's saved and admins are emailed" do
    assert_difference "Lead.count", 1 do
      assert_enqueued_emails User.admin.count do
        post leads_url, params: lead_params
      end
    end
    assert_redirected_to root_url
    assert_match(/Thanks/, flash[:notice])
  end

  test "an invalid submission saves nothing and explains why" do
    assert_no_difference "Lead.count" do
      post leads_url, params: lead_params(email: "nope")
    end
    assert_match(/Email/, flash[:alert])
  end

  test "status can't be set from the public form" do
    post leads_url, params: lead_params(status: "won")
    assert_equal "new", Lead.order(:created_at).last.status
  end

  test "honeypot submissions look successful but save nothing" do
    assert_no_difference "Lead.count" do
      post leads_url, params: lead_params.merge(website: "http://spam.example")
    end
    assert_match(/Thanks/, flash[:notice])
  end

  test "submissions are rate-limited per IP" do
    5.times { |n| post leads_url, params: lead_params(email: "s#{n}@buyer.example") }
    assert_no_difference "Lead.count" do
      post leads_url, params: lead_params(email: "blocked@buyer.example")
    end
    assert_match(/Too many/, flash[:alert])
  end

  test "staff can list and filter leads" do
    sign_in users(:agent)
    get leads_url
    assert_response :success
    assert_match "Pat Prospect", response.body
    get leads_url(status: "won")
    assert_match "Wendy Won", response.body
    assert_no_match "Pat Prospect", response.body
  end

  test "staff can update a lead's status" do
    sign_in users(:admin)
    patch lead_url(leads(:new_lead)), params: { lead: { status: "contacted" } }
    assert_equal "contacted", leads(:new_lead).reload.status
  end

  test "clients and employees can't see or change leads" do
    %i[client employee].each do |role|
      sign_in users(role)
      get leads_url
      assert_redirected_to root_url
      patch lead_url(leads(:new_lead)), params: { lead: { status: "lost" } }
      assert_equal "new", leads(:new_lead).reload.status
      sign_out :user
    end
  end

  test "signed-out visitors can't see leads" do
    get leads_url
    assert_redirected_to new_user_session_url
  end
end
