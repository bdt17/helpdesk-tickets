require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get home_index_url
    assert_response :success
  end

  test "should get dashboard when signed in" do
    sign_in users(:employee)
    get home_dashboard_url
    assert_response :success
  end

  test "dashboard redirects to sign in when unauthenticated" do
    get home_dashboard_url
    assert_redirected_to new_user_session_url
  end
end
