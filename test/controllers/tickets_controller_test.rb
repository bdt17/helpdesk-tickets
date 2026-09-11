require "test_helper"

class TicketsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

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

  test "client only sees their own tickets" do
    ticket = Ticket.create!(title: "Client owned issue", user: users(:client))

    sign_in users(:client)
    get tickets_url
    assert_response :success
    assert_includes @response.body, ticket.title
    assert_not_includes @response.body, tickets(:one).title
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

  test "employee cannot set status, priority, or assignee on their own ticket" do
    sign_in users(:employee)
    ticket = tickets(:one)

    patch ticket_url(ticket), params: {
      ticket: { status: "resolved", priority: "critical", assignee_id: users(:agent).id }
    }

    ticket.reload
    assert ticket.open? # unchanged
    assert ticket.medium? # unchanged
    assert_nil ticket.assignee_id # unchanged
  end

  test "agent can set status, priority, and assignee on any ticket" do
    sign_in users(:agent)
    ticket = tickets(:one)

    patch ticket_url(ticket), params: {
      ticket: { status: "resolved", priority: "critical", assignee_id: users(:agent).id }
    }

    ticket.reload
    assert ticket.resolved?
    assert ticket.critical?
    assert_equal users(:agent), ticket.assignee
  end

  test "resolving a ticket emails its owner" do
    sign_in users(:agent)
    ticket = tickets(:one) # owned by users(:employee)

    assert_enqueued_email_with TicketMailer, :resolved, args: [ ticket, users(:employee) ] do
      patch ticket_url(ticket), params: { ticket: { status: "resolved" } }
    end
  end

  test "does not re-email on an update that isn't a fresh resolution" do
    sign_in users(:agent)
    ticket = tickets(:one)
    ticket.update!(status: :resolved)

    assert_no_enqueued_emails do
      patch ticket_url(ticket), params: { ticket: { priority: "high" } }
    end
  end

  test "owner can rate their resolved ticket" do
    ticket = tickets(:one)
    ticket.update!(status: :resolved)

    sign_in users(:employee)
    patch ticket_satisfaction_url(ticket), params: { ticket: { satisfaction_rating: 4, satisfaction_comment: "Quick fix" } }

    ticket.reload
    assert_equal 4, ticket.satisfaction_rating
    assert_equal "Quick fix", ticket.satisfaction_comment
  end

  test "cannot rate a ticket that is still open" do
    ticket = tickets(:one)

    sign_in users(:employee)
    patch ticket_satisfaction_url(ticket), params: { ticket: { satisfaction_rating: 4 } }

    assert_nil ticket.reload.satisfaction_rating
    assert_equal "You are not authorized to perform that action.", flash[:alert]
  end

  test "cannot rate someone else's ticket" do
    ticket = tickets(:two)
    ticket.update!(status: :resolved)

    sign_in users(:employee) # ticket belongs to other_employee
    patch ticket_satisfaction_url(ticket), params: { ticket: { satisfaction_rating: 1 } }

    assert_nil ticket.reload.satisfaction_rating
  end
end
