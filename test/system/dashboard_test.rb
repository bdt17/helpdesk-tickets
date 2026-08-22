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
    fill_in "Password", with: "password123"
    click_button "Log In"
  end
end
