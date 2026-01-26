class EscalationAlertJob < ApplicationJob
  queue_as :critical_alerts

  def perform(sop_ticket_id)
    ticket = SopTicket.find(sop_ticket_id)

    # CRITICAL tickets > 24h = ESCALATE (matches your schema)
    return unless ticket.priority == 'high' && ticket.created_at < 24.hours.ago

    Rails.logger.warn "🚨 ESCALATION: SopTicket ##{ticket.id} #{ticket.title}"

    # Update status if column exists
    if ticket.has_attribute?(:status)
      ticket.update(status: 'in_progress')
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
end
