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

  test "account edit page requires authentication" do
    get edit_user_registration_url
    assert_redirected_to new_user_session_url
  end

  test "a signed-in user can change their own email with their current password" do
    user = users(:client)
    sign_in user

    patch user_registration_url, params: {
      user: { email: "new-address@example.com", current_password: "password123" }
    }

    assert_redirected_to dashboard_url
    assert_equal "new-address@example.com", user.reload.email
  end

  test "changing email fails without the correct current password" do
    user = users(:client)
    sign_in user

    patch user_registration_url, params: {
      user: { email: "new-address@example.com", current_password: "wrong-password" }
    }

    assert_equal "client-fixture@example.com", user.reload.email
  end

  test "role cannot be changed through the account edit form" do
    user = users(:client)
    sign_in user

    patch user_registration_url, params: {
      user: { role: "admin", current_password: "password123" }
    }

    assert_not user.reload.admin?
  end
end
