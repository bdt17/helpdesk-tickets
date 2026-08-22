class EscalationAlertJob < ApplicationJob
  queue_as :critical_alerts

  def perform(ticket_id)
    ticket = Ticket.find(ticket_id)

    # Already escalated (or no longer overdue - resolved/closed since the
    # sweep found it) - nothing to do. This guard is what makes it safe to
    # call repeatedly from the hourly sweep without re-notifying.
    return unless ticket.overdue? && ticket.escalated_at.nil?

    Rails.logger.warn "🚨 ESCALATION: Ticket ##{ticket.id} #{ticket.title}"

    ticket.status = :in_progress if ticket.open?
    ticket.escalated_at = Time.current
    ticket.save!

    recipients(ticket).each do |recipient|
      TicketMailer.escalated(ticket, recipient).deliver_now
    end

    # ActionCable broadcast (safe even without channel)
    begin
      ActionCable.server.broadcast("ticket_updates", {
        action: "escalated",
        ticket_id: ticket.id,
        message: "⚠️ ##{ticket.id} escalated"
      })
    rescue
      # Ignore if ActionCable not ready
    end
  end

  private

  def recipients(ticket)
    ticket.assignee ? [ticket.assignee] : User.agent.or(User.admin).to_a
  end
end
