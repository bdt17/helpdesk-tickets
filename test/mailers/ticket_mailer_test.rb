require "test_helper"

class TicketMailerTest < ActionMailer::TestCase
  test "comment_posted" do
    comment = tickets(:one).comments.create!(user: users(:employee), body: "Any update on this?")
    mail = TicketMailer.comment_posted(comment, users(:agent))

    assert_equal "New comment on ##{comment.ticket.id} #{comment.ticket.title}", mail.subject
    assert_equal [users(:agent).email], mail.to
    assert_equal ["helpdesk@thomasit.com"], mail.from
    assert_match "Any update on this?", mail.text_part.body.to_s
    assert_match "Any update on this?", mail.html_part.body.to_s
  end

  test "escalated" do
    ticket = tickets(:stale_high_priority)
    mail = TicketMailer.escalated(ticket, users(:agent))

    assert_equal "⚠️ Escalated: ##{ticket.id} #{ticket.title}", mail.subject
    assert_equal [users(:agent).email], mail.to
    assert_match ticket.title, mail.text_part.body.to_s
    assert_match ticket.title, mail.html_part.body.to_s
  end
end
