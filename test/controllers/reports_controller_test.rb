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
end
