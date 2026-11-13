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

  test "filters by status" do
    sign_in users(:agent)
    get tickets_url, params: { status: "in_progress" }

    assert_includes @response.body, tickets(:two).title
    assert_not_includes @response.body, tickets(:one).title
  end

  test "filters by priority" do
    sign_in users(:agent)
    get tickets_url, params: { priority: "high" }

    assert_includes @response.body, tickets(:two).title
    assert_includes @response.body, tickets(:stale_high_priority).title
    assert_not_includes @response.body, tickets(:one).title
  end

  test "filters by category" do
    sign_in users(:agent)
    get tickets_url, params: { category: "hardware" }

    assert_includes @response.body, tickets(:one).title
    assert_not_includes @response.body, tickets(:two).title
  end

  test "filters by assignee" do
    sign_in users(:agent)
    get tickets_url, params: { assignee_id: users(:agent).id }

    assert_includes @response.body, tickets(:two).title
    assert_not_includes @response.body, tickets(:one).title
  end

  test "searches title and description, case-insensitively" do
    sign_in users(:agent)
    get tickets_url, params: { q: "PAYROLL" }

    assert_includes @response.body, tickets(:stale_high_priority).title
    assert_not_includes @response.body, tickets(:one).title
  end

  test "searching description text also matches" do
    sign_in users(:agent)
    get tickets_url, params: { q: "staging environment" }

    assert_includes @response.body, tickets(:two).title
  end

  test "filters combine with policy_scope - a client can't use a filter to see another org's ticket" do
    ticket = Ticket.create!(title: "Client owned issue", user: users(:client), priority: :low)

    sign_in users(:client)
    get tickets_url, params: { priority: "high" } # matches tickets(:two) and (:stale_high_priority), neither the client's

    assert_response :success
    assert_not_includes @response.body, tickets(:two).title
    assert_not_includes @response.body, tickets(:stale_high_priority).title
    assert_includes @response.body, "No tickets match that filter."
  end

  test "shows a distinct empty state for a filter with no matches, vs. having no tickets at all" do
    sign_in users(:agent)
    get tickets_url, params: { q: "nothing matches this" }

    assert_includes @response.body, "No tickets match that filter."
    assert_not_includes @response.body, "No tickets yet."
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

  test "creating a ticket with the category left blank on the real form (submits '', not nil) succeeds" do
    sign_in users(:employee)
    assert_difference("Ticket.count", 1) do
      post tickets_url, params: { ticket: { title: "New issue", category: "" } }
    end
    assert_response :redirect
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

  test "can attach a file when creating a ticket" do
    sign_in users(:employee)

    assert_difference("Ticket.count", 1) do
      post tickets_url, params: { ticket: { title: "Issue with screenshot", attachments: [ fixture_file_upload("test_image.png", "image/png") ] } }
    end

    assert Ticket.last.attachments.attached?
    assert_equal 1, Ticket.last.attachments.count
  end

  test "uploading a disallowed file type on create re-renders with an error and creates nothing" do
    sign_in users(:employee)

    assert_no_difference("Ticket.count") do
      post tickets_url, params: { ticket: { title: "Issue", attachments: [ fixture_file_upload("disallowed.html", "text/html") ] } }
    end

    assert_response :unprocessable_entity
  end

  test "uploading another attachment on update appends rather than replaces" do
    sign_in users(:employee)
    ticket = tickets(:one)
    ticket.attachments.attach(io: file_fixture("test_note.txt").open, filename: "existing.txt", content_type: "text/plain")

    patch ticket_url(ticket), params: { ticket: { attachments: [ fixture_file_upload("test_image.png", "image/png") ] } }

    ticket.reload
    assert_equal 2, ticket.attachments.count
    assert_includes ticket.attachments.map { |a| a.filename.to_s }, "existing.txt"
    assert_includes ticket.attachments.map { |a| a.filename.to_s }, "test_image.png"
  end

  test "an invalid attachment on update is rejected, not silently dropped with a false success" do
    sign_in users(:employee)
    ticket = tickets(:one)

    patch ticket_url(ticket), params: { ticket: { attachments: [ fixture_file_upload("disallowed.html", "text/html") ] } }

    assert_response :unprocessable_entity
    refute ticket.reload.attachments.attached?
  end

  test "agent cannot set a client's ticket priority above their plan's limit" do
    organization = Organization.create!(name: "Acme", plan: "basic", subscription_status: "active")
    client = users(:client)
    client.update!(organization: organization, org_role: "owner")
    ticket = Ticket.create!(title: "Client issue", user: client)

    sign_in users(:agent)
    patch ticket_url(ticket), params: { ticket: { priority: "critical" } }

    assert_response :unprocessable_entity
    assert_equal "medium", ticket.reload.priority
    assert_includes response.body, "exceeds the Basic plan"
  end

  test "agent can set a client's ticket to critical once they're on the Priority plan" do
    organization = Organization.create!(name: "Acme", plan: "priority", subscription_status: "active")
    client = users(:client)
    client.update!(organization: organization, org_role: "owner")
    ticket = Ticket.create!(title: "Client issue", user: client)

    sign_in users(:agent)
    patch ticket_url(ticket), params: { ticket: { priority: "critical" } }

    assert_redirected_to tickets_path
    assert_equal "critical", ticket.reload.priority
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

  test "a free client who has used their free ticket is sent to billing instead of the form" do
    client = users(:client)
    Ticket.create!(title: "Free one", user: client)
    sign_in client

    get new_ticket_url
    assert_redirected_to billing_url
    assert_match(/free ticket/, flash[:alert])

    assert_no_difference "Ticket.count" do
      post tickets_url, params: { ticket: { title: "Sneaky direct POST" } }
    end
    assert_response :unprocessable_entity
  end

  test "a free client still under the limit sees the form and their usage" do
    sign_in users(:client)
    get new_ticket_url
    assert_response :success
    get tickets_url
    assert_select ".alert", text: /0 of 1\s+free tickets/
    assert_select ".alert a[href=?]", billing_path
  end

  test "agents are never limited or shown a usage banner" do
    sign_in users(:agent)
    3.times { |n| post tickets_url, params: { ticket: { title: "Agent ticket #{n}" } } }
    assert_equal 3, Ticket.where(user: users(:agent)).count
    get tickets_url
    assert_select ".alert", text: /tickets used this month/, count: 0
  end

  # --- Intake: a new ticket must reach a human, and say when to expect a reply ---

  test "a new unassigned ticket emails every active staff member and confirms to the filer" do
    sign_in users(:employee)

    assert_enqueued_email_with TicketMailer, :new_ticket, args: ->(args) { args.second == users(:agent) } do
      assert_enqueued_email_with TicketMailer, :new_ticket, args: ->(args) { args.second == users(:admin) } do
        assert_enqueued_email_with TicketMailer, :received, args: ->(args) { args.first.title == "Printer on fire" } do
          post tickets_url, params: { ticket: { title: "Printer on fire" } }
        end
      end
    end
    assert_enqueued_emails 3 # nobody else
  end

  test "a disabled staff account is not emailed about new tickets" do
    users(:admin).update!(status: :disabled)
    sign_in users(:employee)

    post tickets_url, params: { ticket: { title: "Printer on fire" } }

    recipients = enqueued_jobs.select { |j| j["arguments"][1] == "new_ticket" }
    assert_equal 1, recipients.size
  end

  test "staff filing a ticket notify the other staff but get no confirmation themselves" do
    sign_in users(:agent)

    post tickets_url, params: { ticket: { title: "Internal follow-up" } }

    assert_enqueued_emails 1 # admin only: no new_ticket to the agent, no received
  end

  test "after filing, the filer lands on their ticket and is told the response window" do
    sign_in users(:employee)
    post tickets_url, params: { ticket: { title: "New issue", priority: "high" } }

    assert_redirected_to ticket_url(Ticket.last)
    assert_match "respond within 24 hours", flash[:notice]
  end

  test "the filer chooses urgency, which sets the SLA due time" do
    sign_in users(:employee)
    freeze_time do
      post tickets_url, params: { ticket: { title: "Can't log in", priority: "high" } }
      assert_equal "high", Ticket.last.priority
      assert_equal 24.hours.from_now, Ticket.last.due_at
    end
  end

  test "a client cannot pick an urgency above their plan" do
    sign_in users(:client) # not subscribed: capped at medium

    assert_no_difference("Ticket.count") do
      post tickets_url, params: { ticket: { title: "Server down", priority: "critical" } }
    end
    assert_response :unprocessable_entity
  end

  test "a Priority-plan client can file a business-down ticket with a 4-hour SLA" do
    organization = Organization.create!(name: "Acme", plan: "priority", subscription_status: "active")
    users(:client).update!(organization: organization, org_role: "owner")
    sign_in users(:client)

    freeze_time do
      post tickets_url, params: { ticket: { title: "Server down", priority: "critical" } }
      assert_equal "critical", Ticket.last.priority
      assert_equal 4.hours.from_now, Ticket.last.due_at
    end
  end

  test "the new-ticket form only offers urgencies the client's plan allows" do
    sign_in users(:client) # not subscribed: capped at medium
    get new_ticket_url

    assert_select "select[name='ticket[priority]'] option", count: 2
    assert_select "select[name='ticket[priority]'] option[selected][value='medium']"
    assert_includes response.body, "Priority plan"
  end
end
