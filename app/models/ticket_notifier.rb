# Decides who hears about ticket activity. Before this existed, a new
# ticket notified nobody (tickets start unassigned), and a client's reply
# on an unassigned ticket also notified nobody - staff only found out when
# the hourly SLA sweep escalated it, 4 hours to 7 days later.
#
# Rule: an assigned ticket goes to its assignee; an unassigned one (or one
# whose assignee was disabled) goes to every active staff member, so
# something always reaches a human.
class TicketNotifier
  def self.ticket_created(ticket, actor)
    staff_recipients(ticket, except: actor).each do |recipient|
      TicketMailer.new_ticket(ticket, recipient).deliver_later
    end

    # Confirmation for the person who filed it - skipped when staff file a
    # ticket for themselves, since they already know.
    TicketMailer.received(ticket).deliver_later if actor == ticket.user && !actor.staff?
  end

  def self.comment_posted(comment, actor)
    ticket = comment.ticket
    people = if comment.internal?
      staff_recipients(ticket)
    else
      [ ticket.user ] + staff_recipients(ticket)
    end

    (people.compact.uniq - [ actor ]).select(&:active?).each do |recipient|
      TicketMailer.comment_posted(comment, recipient).deliver_later
    end
  end

  # Someone else handed this ticket to a staff member - tell them, since
  # nothing else would until the client replies or the SLA sweep fires.
  def self.ticket_assigned(ticket, actor)
    assignee = ticket.assignee
    return if assignee.nil? || assignee == actor || !assignee.active?

    TicketMailer.assigned(ticket, assignee, actor).deliver_later
  end

  def self.staff_recipients(ticket, except: nil)
    # A disabled assignee can't act on it, so fall back to the whole team.
    assignee = ticket.assignee if ticket.assignee&.active?
    people = assignee ? [ assignee ] : User.staff.active.to_a
    people - [ except ]
  end
end
