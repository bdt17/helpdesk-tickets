require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { Rails.cache.clear }

  test "a correct password signs in" do
    post user_session_url, params: { user: { email: users(:client).email, password: "password1234" } }
    assert_response :see_other
    get dashboard_url
    assert_response :success
  end

  test "sign-in is rate-limited per IP across different accounts" do
    # Spread over several accounts so lockable (per-account, 5 failures)
    # never kicks in - this is the credential-stuffing case it can't stop.
    emails = %i[employee other_employee agent admin client].map { |name| users(name).email }
    10.times do |n|
      post user_session_url, params: { user: { email: emails[n % emails.size], password: "wrong-password" } }
    end

    post user_session_url, params: { user: { email: users(:client).email, password: "password1234" } }

    assert_redirected_to new_user_session_url
    assert_equal "Too many sign-in attempts. Please try again in a few minutes.", flash[:alert]
    get dashboard_url
    assert_redirected_to new_user_session_url
  end
end
