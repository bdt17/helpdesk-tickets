require "test_helper"

class AgentsControllerTest < ActionDispatch::IntegrationTest
  test "redirects to sign in when unauthenticated" do
    get agents_url
    assert_redirected_to new_user_session_url
  end

  test "client cannot view the staff roster" do
    sign_in users(:client)
    get agents_url
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform that action.", flash[:alert]
  end

  test "employee cannot view the staff roster" do
    sign_in users(:employee)
    get agents_url
    assert_redirected_to root_url
  end

  test "agent can view the staff roster" do
    sign_in users(:agent)
    get agents_url
    assert_response :success
  end

  test "admin can view the staff roster" do
    sign_in users(:admin)
    get agents_url
    assert_response :success
  end
end
