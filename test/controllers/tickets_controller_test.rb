require "test_helper"

class TicketsControllerTest < ActionDispatch::IntegrationTest
  test "redirects to sign in when not authenticated" do
    get tickets_url
    assert_redirected_to new_user_session_url
  end

  test "employee only sees their own tickets" do
    sign_in users(:employee)
    get tickets_url
    assert_response :success
    assert_includes @response.body, tickets(:one).title
    assert_not_includes @response.body, tickets(:two).title
  end

  test "agent sees every ticket" do
    sign_in users(:agent)
    get tickets_url
    assert_response :success
    assert_includes @response.body, tickets(:one).title
    assert_includes @response.body, tickets(:two).title
  end

  test "employee cannot view another employee's ticket" do
    sign_in users(:employee)
    get ticket_url(tickets(:two))
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform that action.", flash[:alert]
  end

  test "creating a ticket assigns the current user as owner" do
    sign_in users(:employee)
    assert_difference("Ticket.count", 1) do
      post tickets_url, params: { ticket: { title: "New issue" } }
    end
    assert_equal users(:employee), Ticket.last.user
  end
end
