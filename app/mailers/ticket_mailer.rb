class TicketMailer < ApplicationMailer
  # To staff: a ticket just came in.
  def new_ticket(ticket, recipient)
    @ticket = ticket
    @recipient = recipient

    prefix = ticket.critical? || ticket.high? ? "[#{ticket.priority.upcase}] " : ""
    mail(to: recipient.email, subject: "#{prefix}New ticket ##{ticket.id} #{ticket.title}")
  end

  # To the person who filed it: we've got it, here's when to expect a reply.
  def received(ticket)
    @ticket = ticket
    @recipient = ticket.user
    @response_window = Ticket::SLA_WINDOWS.fetch(ticket.priority.to_sym).inspect

    mail(to: @recipient.email, subject: "We received your ticket ##{ticket.id} #{ticket.title}")
  end

  def comment_posted(comment, recipient)
    @comment = comment
    @ticket = comment.ticket
    @recipient = recipient

    mail(to: recipient.email, subject: "New comment on ##{@ticket.id} #{@ticket.title}")
  end

  def escalated(ticket, recipient)
    @ticket = ticket
    @recipient = recipient

    mail(to: recipient.email, subject: "⚠️ Escalated: ##{@ticket.id} #{@ticket.title}")
  end

  def resolved(ticket, recipient)
    @ticket = ticket
    @recipient = recipient

    mail(to: recipient.email, subject: "Resolved: ##{@ticket.id} #{@ticket.title}")
  end
end
