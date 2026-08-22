class TicketMailer < ApplicationMailer
  def comment_posted(comment, recipient)
    @comment = comment
    @ticket = comment.ticket
    @recipient = recipient

    mail(to: recipient.email, subject: "New comment on ##{@ticket.id} #{@ticket.title}")
  end
end
