require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup { Rails.cache.clear }

  test "a known email gets a reset email" do
    assert_emails 1 do
      post user_password_url, params: { user: { email: users(:client).email } }
    end
  end

  test "an unknown email gets the same response as a known one (no account enumeration)" do
    post user_password_url, params: { user: { email: users(:client).email } }
    known = [ response.status, response.location, flash[:notice] ]

    assert_no_emails do
      post user_password_url, params: { user: { email: "nobody-here@example.com" } }
    end
    assert_equal known, [ response.status, response.location, flash[:notice] ]
  end

  test "reset requests are rate-limited per IP" do
    5.times { post user_password_url, params: { user: { email: users(:client).email } } }

    assert_no_emails do
      post user_password_url, params: { user: { email: users(:client).email } }
    end
    assert_redirected_to new_user_password_url
    assert_equal "Too many password reset requests. Please try again in a bit.", flash[:alert]
  end
end
