class EscalationAlertJob < ApplicationJob
  queue_as :critical_alerts

  def perform(ticket_id)
    ticket = Ticket.find(ticket_id)

    # High/critical tickets open more than 24h = ESCALATE
    return unless (ticket.high? || ticket.critical?) && ticket.created_at < 24.hours.ago
    return if ticket.resolved? || ticket.closed?

    Rails.logger.warn "🚨 ESCALATION: Ticket ##{ticket.id} #{ticket.title}"

    ticket.update(status: :in_progress)

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
end
