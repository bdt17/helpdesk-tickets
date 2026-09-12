require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup { Rails.cache.clear }

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

  test "signing up sends a welcome email" do
    post user_registration_url, params: {
      user: { email: "new-client@example.com", password: "password123", password_confirmation: "password123" }
    }

    user = User.find_by(email: "new-client@example.com")
    assert_enqueued_email_with UserMailer, :welcome, args: [ user ]
  end

  test "a failed sign up does not send a welcome email" do
    assert_no_enqueued_emails do
      post user_registration_url, params: {
        user: { email: "not-an-email", password: "short", password_confirmation: "different" }
      }
    end
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

  test "signup is rate-limited per IP after 5 attempts within an hour" do
    5.times do |n|
      post user_registration_url, params: {
        user: { email: "rl-#{n}@example.com", password: "password123", password_confirmation: "password123" }
      }
      # A successful signup auto-signs the new user in, and Devise itself
      # refuses to process another signup for an already-authenticated
      # session (require_no_authentication) - sign back out between
      # attempts so all 5 genuinely reach the rate limiter, the same way
      # 5 signups from 5 different anonymous browser tabs would.
      sign_out :user
    end

    assert_no_difference "User.count" do
      post user_registration_url, params: {
        user: { email: "rl-blocked@example.com", password: "password123", password_confirmation: "password123" }
      }
    end

    assert_redirected_to new_user_registration_url
    assert_equal "Too many signup attempts. Please try again in a bit.", flash[:alert]
  end

  test "the account-edit action isn't affected by the signup rate limit" do
    user = users(:client)

    5.times do |n|
      post user_registration_url, params: {
        user: { email: "rl2-#{n}@example.com", password: "password123", password_confirmation: "password123" }
      }
    end

    sign_in user
    patch user_registration_url, params: { user: { email: "still-works@example.com", current_password: "password123" } }

    assert_equal "still-works@example.com", user.reload.email
  end
end
