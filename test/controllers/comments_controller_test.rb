require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    tickets(:two).update!(assignee: users(:agent)) # ticket owned by other_employee, assigned to agent
  end

  test "redirects to sign in when not authenticated" do
    post ticket_comments_url(tickets(:one)), params: { comment: { body: "hi" } }
    assert_redirected_to new_user_session_url
  end

  test "owner can comment on their own ticket" do
    sign_in users(:employee)
    assert_difference("Comment.count", 1) do
      post ticket_comments_url(tickets(:one)), params: { comment: { body: "Any update?" } }
    end
    assert_redirected_to ticket_url(tickets(:one))
  end

  test "an unrelated employee cannot comment on someone else's ticket" do
    sign_in users(:employee)
    assert_no_difference("Comment.count") do
      post ticket_comments_url(tickets(:two)), params: { comment: { body: "Any update?" } }
    end
  end

  test "agent can comment and mark a comment internal" do
    sign_in users(:agent)
    assert_difference("Comment.count", 1) do
      post ticket_comments_url(tickets(:two)), params: { comment: { body: "Working on it", internal: true } }
    end
    assert Comment.last.internal?
  end

  test "an employee's attempt to mark a comment internal is ignored" do
    sign_in users(:employee)
    post ticket_comments_url(tickets(:one)), params: { comment: { body: "Any update?", internal: true } }
    refute Comment.last.internal?
  end

  test "internal comments are hidden from the ticket owner but visible to staff" do
    internal_comment = tickets(:two).comments.create!(user: users(:agent), body: "internal note", internal: true)

    sign_in users(:other_employee) # owner of ticket two
    get ticket_url(tickets(:two))
    assert_not_includes @response.body, internal_comment.body

    sign_in users(:agent)
    get ticket_url(tickets(:two))
    assert_includes @response.body, internal_comment.body
  end

  test "posting a regular comment emails the other participants, excluding the author" do
    sign_in users(:employee) # owner of ticket two? no - owner of ticket one
    tickets(:one).update!(assignee: users(:agent))

    assert_emails 1 do
      post ticket_comments_url(tickets(:one)), params: { comment: { body: "Any update?" } }
    end
    assert_equal [ users(:agent).email ], ActionMailer::Base.deliveries.last.to
  end

  test "posting an internal comment does not email the ticket owner" do
    sign_in users(:agent) # assignee of ticket two
    assert_emails 0 do
      post ticket_comments_url(tickets(:two)), params: { comment: { body: "internal note", internal: true } }
    end
  end
end
