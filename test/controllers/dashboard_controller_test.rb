require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "redirects to sign in when not authenticated" do
    get dashboard_url
    assert_redirected_to new_user_session_url
  end

  test "employee's dashboard only reflects their own tickets" do
    sign_in users(:employee)
    get dashboard_url
    assert_response :success
    assert_includes @response.body, tickets(:one).title
    assert_includes @response.body, tickets(:stale_high_priority).title
    assert_not_includes @response.body, tickets(:two).title
  end

  test "agent's dashboard reflects every ticket, including overdue ones" do
    sign_in users(:agent)
    get dashboard_url
    assert_response :success
    assert_includes @response.body, tickets(:one).title
    assert_includes @response.body, tickets(:two).title
    assert_includes @response.body, tickets(:stale_high_priority).title
  end

  test "every signed-in role can reach the ticket form from the top nav" do
    %i[client employee agent admin].each do |role|
      sign_in users(role)
      get dashboard_url
      assert_select "nav a[href=?]", new_ticket_path, text: "Open a Ticket"
      assert_select "nav a[href=?]", tickets_path, text: "Tickets"
      sign_out :user
    end
  end
end
