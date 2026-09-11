# Enqueued from Ticket#after_create_commit when a client files a ticket
# without picking a category. Safe to skip entirely (see
# TicketCategorizer.configured?) — a ticket left "manual" with a blank
# category behaves exactly as it did before this feature existed.
class TicketCategorizationJob < ApplicationJob
  queue_as :default

  def perform(ticket_id)
    ticket = Ticket.find_by(id: ticket_id)
    return unless ticket&.category.blank?

    category = TicketCategorizer.call(ticket)
    return unless category

    ticket.update!(category: category, category_source: "ai")

    ActionCable.server.broadcast("ticket_updates", {
      action: "ai_categorized",
      ticket_id: ticket.id,
      message: "🤖 ##{ticket.id} auto-categorized as #{category}"
    })
  rescue StandardError => e
    Rails.logger.warn "TicketCategorizationJob failed for ticket ##{ticket_id}: #{e.class} #{e.message}"
  end
end
