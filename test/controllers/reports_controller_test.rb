require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  test "should get index when signed in" do
    sign_in users(:employee)
    get reports_index_url
    assert_response :success
  end

  test "redirects to sign in when unauthenticated" do
    get reports_index_url
    assert_redirected_to new_user_session_url
  end
end
