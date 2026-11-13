require "test_helper"

class TicketMailerTest < ActionMailer::TestCase
  test "comment_posted" do
    comment = tickets(:one).comments.create!(user: users(:employee), body: "Any update on this?")
    mail = TicketMailer.comment_posted(comment, users(:agent))

    assert_equal "New comment on ##{comment.ticket.id} #{comment.ticket.title}", mail.subject
    assert_equal [ users(:agent).email ], mail.to
    assert_equal [ "support@thomasinformationtechnology.com" ], mail.from
    assert_match "Any update on this?", mail.text_part.body.to_s
    assert_match "Any update on this?", mail.html_part.body.to_s
  end

  test "escalated" do
    ticket = tickets(:stale_high_priority)
    mail = TicketMailer.escalated(ticket, users(:agent))

    assert_equal "⚠️ Escalated: ##{ticket.id} #{ticket.title}", mail.subject
    assert_equal [ users(:agent).email ], mail.to
    assert_match ticket.title, mail.text_part.body.to_s
    assert_match ticket.title, mail.html_part.body.to_s
  end

  test "resolved" do
    ticket = tickets(:one)
    ticket.update!(status: :resolved)
    mail = TicketMailer.resolved(ticket, users(:employee))

    assert_equal "Resolved: ##{ticket.id} #{ticket.title}", mail.subject
    assert_equal [ users(:employee).email ], mail.to
    assert_match ticket.title, mail.text_part.body.to_s
    assert_match ticket.title, mail.html_part.body.to_s
  end

  test "new_ticket flags urgent tickets in the subject" do
    ticket = tickets(:one)
    ticket.update!(priority: :critical)
    mail = TicketMailer.new_ticket(ticket, users(:agent))

    assert_equal "[CRITICAL] New ticket ##{ticket.id} #{ticket.title}", mail.subject
    assert_equal [ users(:agent).email ], mail.to
    assert_match ticket.user.email, mail.text_part.body.to_s
    assert_match "/tickets/#{ticket.id}", mail.html_part.body.to_s
  end

  test "received tells the filer when to expect a reply" do
    ticket = tickets(:one)
    ticket.update!(priority: :high)
    mail = TicketMailer.received(ticket)

    assert_equal "We received your ticket ##{ticket.id} #{ticket.title}", mail.subject
    assert_equal [ ticket.user.email ], mail.to
    assert_match "within 24 hours", mail.text_part.body.to_s
    assert_match "within 24 hours", mail.html_part.body.to_s
  end
end
