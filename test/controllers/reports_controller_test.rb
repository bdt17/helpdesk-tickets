require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  test "redirects to sign in when unauthenticated" do
    get reports_index_url
    assert_redirected_to new_user_session_url
  end

  test "client cannot view reports" do
    sign_in users(:client)
    get reports_index_url
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform that action.", flash[:alert]
  end

  test "employee cannot view reports" do
    sign_in users(:employee)
    get reports_index_url
    assert_redirected_to root_url
  end

  test "agent can view reports" do
    sign_in users(:agent)
    get reports_index_url
    assert_response :success
  end

  test "admin can view reports" do
    sign_in users(:admin)
    get reports_index_url
    assert_response :success
  end

  test "computes CSAT average only from rated tickets" do
    tickets(:one).update!(status: :resolved, satisfaction_rating: 4)
    tickets(:two).update!(status: :resolved, satisfaction_rating: 2)

    sign_in users(:admin)
    get reports_index_url

    assert_response :success
    assert_includes @response.body, "3.0 / 5"
    assert_includes @response.body, "2 responses"
  end

  test "computes per-agent open/resolved counts and average resolution time" do
    tickets(:two).update!(assignee: users(:agent), status: :in_progress) # stays open
    resolved = tickets(:stale_high_priority)
    resolved.update_columns(assignee_id: users(:agent).id, created_at: 10.hours.ago)
    resolved.update!(status: :resolved)
    resolved.update_columns(resolved_at: Time.current) # exactly 10 hours after creation

    sign_in users(:admin)
    get reports_index_url

    assert_response :success
    assert_includes @response.body, users(:agent).email
    assert_includes @response.body, "10.0 hrs"
  end

  test "admins see estimated revenue from paying organizations only" do
    Organization.create!(name: "A", subscription_status: "active", plan: "basic")
    Organization.create!(name: "B", subscription_status: "active", plan: "priority")
    Organization.create!(name: "C", subscription_status: "trialing", plan: "business")
    Organization.create!(name: "D", subscription_status: "canceled", plan: "priority")

    sign_in users(:admin)
    get reports_index_url
    assert_response :success
    assert_select "h2", text: "$597" # 49 + 399 + 149 (trialing counted, canceled not)
    assert_match "System health", response.body
  end

  test "system health reflects configuration" do
    ENV["SMTP_ADDRESS"] = "smtp.example.com"
    sign_in users(:admin)
    get reports_index_url
    assert_select "li.health-check[data-ok=true]", text: /Outgoing email configured/
    assert_select "li.health-check[data-ok=false]", text: /persistent disk/
  ensure
    ENV.delete("SMTP_ADDRESS")
  end

  test "agents see reports but not revenue" do
    sign_in users(:agent)
    get reports_index_url
    assert_response :success
    assert_no_match "Est. monthly revenue", response.body
    assert_no_match "System health", response.body
  end

  test "annual subscribers count toward MRR at a twelfth of their yearly price" do
    Organization.create!(name: "Yearly", subscription_status: "active", plan: "business", billing_interval: "year") # 1490/12 = 124.17
    Organization.create!(name: "Monthly", subscription_status: "active", plan: "basic", billing_interval: "month") # 49

    sign_in users(:admin)
    get reports_index_url
    assert_select "h2", text: "$173"
  end
end
