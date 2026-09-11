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
end
