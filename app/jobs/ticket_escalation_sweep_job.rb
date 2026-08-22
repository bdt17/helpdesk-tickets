class TicketEscalationSweepJob < ApplicationJob
  queue_as :default

  def perform
    Ticket.overdue.where(escalated_at: nil).find_each do |ticket|
      EscalationAlertJob.perform_later(ticket.id)
    end
  end
end
