require "test_helper"

class TwoFactorTest < ActionDispatch::IntegrationTest
  FIXTURE_SECRET = "JBSWY3DPEHPK3PXP".freeze

  setup do
    Rails.cache.clear
    @agent = users(:agent)
  end

  def current_code(secret = FIXTURE_SECRET)
    ROTP::TOTP.new(secret).now
  end

  def sign_in_with_password(user, remember: false)
    post user_session_url, params: { user: { email: user.email, password: "password1234", remember_me: remember ? "1" : "0" } }
  end

  def assert_signed_out
    get dashboard_url
    assert_redirected_to new_user_session_url
  end

  def assert_signed_in
    get dashboard_url
    assert_response :success
  end

  # --- signing in ---------------------------------------------------------

  test "the fixture secret is encrypted at rest" do
    raw = User.connection.select_value("SELECT otp_secret FROM users WHERE id = #{@agent.id}")
    assert_not_includes raw, FIXTURE_SECRET
    assert_equal FIXTURE_SECRET, @agent.reload.otp_secret
  end

  test "a correct password alone does not sign in a 2FA account" do
    sign_in_with_password(@agent)
    assert_redirected_to new_two_factor_session_url
    assert_signed_out
  end

  test "password then a correct code signs in" do
    sign_in_with_password(@agent)
    post two_factor_session_url, params: { code: current_code }
    assert_redirected_to root_url
    assert_signed_in
  end

  test "a wrong password never reaches the code step" do
    post user_session_url, params: { user: { email: @agent.email, password: "wrong-password" } }
    assert_response :unprocessable_entity
    get new_two_factor_session_url
    assert_redirected_to new_user_session_url
  end

  test "the code step can't be used without the password step" do
    post two_factor_session_url, params: { code: current_code }
    assert_redirected_to new_user_session_url
    assert_signed_out
  end

  test "a wrong code is refused and counts as a failed sign-in" do
    sign_in_with_password(@agent)
    post two_factor_session_url, params: { code: "000000" }
    assert_response :unprocessable_entity
    assert_equal 1, @agent.reload.failed_attempts
    assert_signed_out
  end

  test "five wrong codes lock the account" do
    sign_in_with_password(@agent)
    5.times { post two_factor_session_url, params: { code: "000000" } }

    assert_redirected_to new_user_session_url
    assert @agent.reload.access_locked?
    post two_factor_session_url, params: { code: current_code }
    assert_signed_out
  end

  test "re-entering the password doesn't reset the wrong-code count" do
    sign_in_with_password(@agent)
    4.times { post two_factor_session_url, params: { code: "000000" } }
    sign_in_with_password(@agent)
    assert_equal 4, @agent.reload.failed_attempts

    post two_factor_session_url, params: { code: "000000" }
    assert @agent.reload.access_locked?
  end

  test "a full sign-in resets the wrong-code count" do
    sign_in_with_password(@agent)
    2.times { post two_factor_session_url, params: { code: "000000" } }
    post two_factor_session_url, params: { code: current_code }
    assert_signed_in
    assert_equal 0, @agent.reload.failed_attempts
  end

  test "the same code can't be used twice" do
    sign_in_with_password(@agent)
    code = current_code
    post two_factor_session_url, params: { code: code }
    assert_signed_in
    delete destroy_user_session_url

    sign_in_with_password(@agent)
    post two_factor_session_url, params: { code: code }
    assert_response :unprocessable_entity
    assert_signed_out
  end

  test "the code step expires after five minutes" do
    sign_in_with_password(@agent)
    travel 6.minutes do
      post two_factor_session_url, params: { code: current_code }
      assert_redirected_to new_user_session_url
      assert_signed_out
    end
  end

  test "a disabled account can't finish the code step" do
    sign_in_with_password(@agent)
    @agent.update!(status: :disabled)
    post two_factor_session_url, params: { code: current_code }
    assert_redirected_to new_user_session_url
    assert_signed_out
  end

  test "a backup code works once" do
    codes = @agent.regenerate_backup_codes!

    sign_in_with_password(@agent)
    post two_factor_session_url, params: { code: codes.first.upcase }
    assert_signed_in
    assert_equal 9, @agent.reload.backup_codes_remaining
    delete destroy_user_session_url

    sign_in_with_password(@agent)
    post two_factor_session_url, params: { code: codes.first }
    assert_response :unprocessable_entity
  end

  test "remember me is kept through the code step" do
    sign_in_with_password(@agent, remember: true)
    assert_nil cookies["remember_user_token"].presence
    post two_factor_session_url, params: { code: current_code }
    assert cookies["remember_user_token"].present?
  end

  test "clients without 2FA still sign in with just a password" do
    sign_in_with_password(users(:client))
    assert_response :see_other
    assert_signed_in
  end

  test "a password reset doesn't sign a 2FA account in" do
    token = @agent.send_reset_password_instructions
    put user_password_url, params: { user: { reset_password_token: token, password: "new-password-5678", password_confirmation: "new-password-5678" } }
    assert_redirected_to new_user_session_url
    assert_signed_out
  end

  # --- setting it up ------------------------------------------------------

  test "staff without 2FA are sent to set it up on every page" do
    @agent.reset_two_factor!
    sign_in @agent
    get tickets_url
    assert_redirected_to two_factor_setup_url
    get reports_index_url
    assert_redirected_to two_factor_setup_url
  end

  test "setting up 2FA with a correct code turns it on and shows backup codes once" do
    @agent.reset_two_factor!
    sign_in @agent
    get two_factor_setup_url
    assert_response :success
    assert_equal "no-store", response.headers["Cache-Control"]
    secret = session[:two_factor_setup_secret]
    assert_includes response.body, secret.scan(/.{1,4}/).join(" ")

    post two_factor_setup_url, params: { code: current_code(secret) }
    assert_response :success
    assert_select ".font-monospace .col", 10
    assert @agent.reload.two_factor_enabled?
    assert_equal secret, @agent.otp_secret

    get tickets_url
    assert_response :success
  end

  test "setting up with a wrong code leaves 2FA off" do
    @agent.reset_two_factor!
    sign_in @agent
    get two_factor_setup_url
    post two_factor_setup_url, params: { code: "000000" }
    assert_redirected_to two_factor_setup_url
    assert_not @agent.reload.two_factor_enabled?
  end

  test "clients can't open the 2FA setup page" do
    sign_in users(:client)
    get two_factor_setup_url
    assert_redirected_to root_url
  end

  test "new backup codes need a current authenticator code" do
    old_codes = @agent.regenerate_backup_codes!
    sign_in @agent

    post two_factor_backup_codes_url, params: { code: old_codes.first }
    assert_redirected_to two_factor_setup_url

    post two_factor_backup_codes_url, params: { code: current_code }
    assert_response :success
    assert_not_includes response.body, old_codes.second
    assert_nil @agent.reload.verify_second_factor!(old_codes.second)
  end

  # --- admin reset --------------------------------------------------------

  test "an admin can reset another staff member's 2FA" do
    sign_in users(:admin)
    patch admin_user_url(@agent), params: { reset_two_factor: "1" }
    assert_redirected_to admin_users_url
    assert_not @agent.reload.two_factor_enabled?
  end

  test "an admin can't reset their own 2FA" do
    admin = users(:admin)
    sign_in admin
    patch admin_user_url(admin), params: { reset_two_factor: "1" }
    assert admin.reload.two_factor_enabled?
  end

  test "agents can't reset anyone's 2FA" do
    sign_in @agent
    patch admin_user_url(users(:admin)), params: { reset_two_factor: "1" }
    assert_redirected_to root_url
    assert users(:admin).reload.two_factor_enabled?
  end
end
