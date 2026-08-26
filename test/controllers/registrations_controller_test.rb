require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "sign up page is reachable without authentication" do
    get new_user_registration_url
    assert_response :success
  end

  test "signing up creates a client and signs them in" do
    assert_difference "User.count", 1 do
      post user_registration_url, params: {
        user: { email: "new-client@example.com", password: "password123", password_confirmation: "password123" }
      }
    end

    user = User.find_by(email: "new-client@example.com")
    assert user.client?
    assert_redirected_to new_ticket_url
  end

  test "role cannot be elevated through the sign up form" do
    post user_registration_url, params: {
      user: { email: "sneaky@example.com", password: "password123", password_confirmation: "password123", role: "admin" }
    }

    user = User.find_by(email: "sneaky@example.com")
    assert user.client?
    assert_not user.admin?
  end
end
