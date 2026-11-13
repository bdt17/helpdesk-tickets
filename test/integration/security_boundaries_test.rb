require "test_helper"

# Attack-style regression tests: each one tries to cross a boundary an
# attacker would go after (another company's data, staff-only pages,
# privilege escalation, mass assignment, stored XSS) and asserts it fails.
class SecurityBoundariesTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    Rails.cache.clear
    @acme = Organization.create!(name: "Acme", plan: "priority", subscription_status: "active")
    @globex = Organization.create!(name: "Globex", plan: "priority", subscription_status: "active")
    @acme_owner = users(:client)
    @acme_owner.update!(organization: @acme, org_role: "owner")
    @globex_owner = User.create!(email: "owner@globex.test", password: "password1234", role: :client, organization: @globex, org_role: "owner")
    @globex_member = User.create!(email: "member@globex.test", password: "password1234", role: :client, organization: @globex, org_role: "member")

    @globex_ticket = Ticket.create!(title: "Globex secret", description: "VPN creds rotated", user: @globex_owner)
    @globex_ticket.attachments.attach(io: file_fixture("test_image.png").open, filename: "secret.png", content_type: "image/png")
    @globex_ticket.comments.create!(user: users(:agent), body: "internal-only note", internal: true)
    @acme_ticket = Ticket.create!(title: "Acme issue", user: @acme_owner)
  end

  # --- Another company's data -------------------------------------------

  test "a client cannot view, edit, comment on, rate, or download from another company's ticket" do
    sign_in @acme_owner

    get ticket_url(@globex_ticket)
    assert_redirected_to root_url

    patch ticket_url(@globex_ticket), params: { ticket: { title: "pwned" } }
    assert_equal "Globex secret", @globex_ticket.reload.title

    assert_no_difference("Comment.count") do
      post ticket_comments_url(@globex_ticket), params: { comment: { body: "hi" } }
    end

    @globex_ticket.update!(status: :resolved)
    patch ticket_satisfaction_url(@globex_ticket), params: { ticket: { satisfaction_rating: 1 } }
    assert_nil @globex_ticket.reload.satisfaction_rating

    get ticket_attachment_url(@globex_ticket, @globex_ticket.attachments.first)
    assert_redirected_to root_url
  end

  test "a client cannot fetch another company's attachment through their own ticket's URL" do
    sign_in @acme_owner
    get ticket_attachment_url(@acme_ticket, @globex_ticket.attachments.first)
    assert_response :not_found
  end

  test "another company's tickets never appear in a client's list or search" do
    sign_in @acme_owner
    get tickets_url, params: { q: "Globex" }
    assert_not_includes response.body, "Globex secret"
  end

  test "a client cannot remove another company's team member" do
    sign_in @acme_owner
    delete team_member_url(@globex_member)
    assert_equal @globex, @globex_member.reload.organization
  end

  test "a team member who is not the owner cannot invite people" do
    sign_in @globex_member
    assert_no_difference("User.count") do
      post team_invite_url, params: { email: "attacker@evil.test" }
    end
  end

  # --- Client vs staff ---------------------------------------------------

  test "internal staff notes are never shown to the client" do
    sign_in @globex_owner
    get ticket_url(@globex_ticket)
    assert_response :success
    assert_not_includes response.body, "internal-only note"
  end

  test "a client cannot reach any staff-only page" do
    sign_in @acme_owner
    [ reports_index_url, leads_url, agents_url, admin_users_url, api_ai_status_url, new_article_url ].each do |url|
      get url
      assert_response :redirect, "#{url} should not be reachable by a client"
      assert_not_equal url, response.location
    end
  end

  test "a client cannot log time, edit leads, or publish help articles" do
    sign_in @acme_owner
    lead = Lead.create!(name: "X", email: "x@example.com", message: "hi")

    assert_no_difference("TimeEntry.count") do
      post ticket_time_entries_url(@acme_ticket), params: { time_entry: { minutes: 600 } }
    end
    patch lead_url(lead), params: { lead: { status: "won" } }
    assert_not_equal "won", lead.reload.status
    assert_no_difference("Article.count") do
      post articles_url, params: { article: { title: "Phish", body: "click here", published: true } }
    end
  end

  test "a client cannot post an internal note or set status/assignee/owner when filing" do
    sign_in @acme_owner

    post ticket_comments_url(@acme_ticket), params: { comment: { body: "x", internal: true } }
    refute Comment.last.internal?

    post tickets_url, params: { ticket: { title: "t", status: "closed", assignee_id: users(:agent).id, user_id: @globex_owner.id } }
    t = Ticket.last
    assert t.open?
    assert_nil t.assignee_id
    assert_equal @acme_owner, t.user
  end

  test "a client cannot change a ticket's priority after filing" do
    sign_in @acme_owner
    patch ticket_url(@acme_ticket), params: { ticket: { priority: "critical" } }
    assert_equal "medium", @acme_ticket.reload.priority
  end

  # --- Privilege escalation ----------------------------------------------

  test "public signup can only ever create a client" do
    post user_registration_url, params: { user: { email: "evil@evil.test", password: "password12345", password_confirmation: "password12345", role: "admin" } }
    assert User.find_by(email: "evil@evil.test").client?
  end

  test "a user cannot change their own role from the account page" do
    sign_in @acme_owner
    patch user_registration_url, params: { user: { role: "admin", current_password: "password1234" } }
    assert @acme_owner.reload.client?
  end

  test "an agent cannot reach admin user management or promote themselves" do
    agent = users(:agent)
    sign_in agent
    get admin_users_url
    assert_response :redirect
    patch admin_user_url(agent), params: { role: "admin" }
    assert agent.reload.agent?
  end

  test "an admin cannot turn a client into staff" do
    sign_in users(:admin)
    patch admin_user_url(@acme_owner), params: { role: "admin" }
    assert @acme_owner.reload.client?
  end

  test "a disabled account cannot sign in" do
    @acme_owner.update!(status: :disabled)
    post user_session_url, params: { user: { email: @acme_owner.email, password: "password1234" } }
    get tickets_url
    assert_redirected_to new_user_session_url
  end

  # --- Injection / XSS ---------------------------------------------------

  test "script in a ticket title or comment is escaped on the page and in email" do
    payload = "<script>alert(1)</script>"
    sign_in @acme_owner
    post tickets_url, params: { ticket: { title: payload, description: payload } }
    ticket = Ticket.last
    post ticket_comments_url(ticket), params: { comment: { body: payload } }

    sign_in users(:agent)
    get ticket_url(ticket)
    assert_not_includes response.body, payload
    assert_includes response.body, "&lt;script&gt;"

    html = TicketMailer.comment_posted(ticket.comments.last, users(:agent)).html_part.body.to_s
    assert_not_includes html, payload
  end

  test "search input is not interpreted as SQL" do
    sign_in users(:agent)
    get tickets_url, params: { q: "' OR 1=1 --" }
    assert_response :success
    assert_not_includes response.body, "Globex secret"
  end

  # --- Unauthenticated ---------------------------------------------------

  test "a Stripe webhook without a valid signature is rejected" do
    post webhooks_stripe_url, params: { type: "customer.subscription.deleted" }.to_json,
         headers: { "Content-Type" => "application/json", "Stripe-Signature" => "t=1,v1=forged" }
    assert_response :bad_request
    assert @globex.reload.subscribed?
  end

  test "a password reset request does not reveal whether an email has an account" do
    post user_password_url, params: { user: { email: @acme_owner.email } }
    known = [ response.status, response.location ]
    post user_password_url, params: { user: { email: "nobody-#{SecureRandom.hex(4)}@example.com" } }
    assert_equal known, [ response.status, response.location ]
  end
end
