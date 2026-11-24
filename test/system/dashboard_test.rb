require "application_system_test_case"

class DashboardTest < ApplicationSystemTestCase
  test "an employee sees their own dashboard" do
    sign_in_via_form(users(:employee))

    visit dashboard_path

    assert_selector "h1", text: "My Dashboard"
    assert_text "Total Tickets"
    assert_text "Overdue"
  end

  test "an agent sees the team dashboard" do
    sign_in_via_form(users(:agent))

    visit dashboard_path

    assert_selector "h1", text: "Team Dashboard"
  end

  private

  def sign_in_via_form(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password1234"
    click_button "Log In"
    if user.two_factor_enabled?
      # Staff fixtures have 2FA on: the password step leads to the code step.
      assert_text "Two-factor sign-in"
      fill_in "Code", with: ROTP::TOTP.new(user.otp_secret).now
      click_button "Verify"
    end
    # Wait for the sign-in to actually land before the caller's next
    # visit - otherwise that visit can race the form submission, arrive
    # without the session cookie, and get bounced back to the login page.
    assert_text "Welcome, #{user.email}"
  end
end
