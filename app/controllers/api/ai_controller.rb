# Used to be a fully hardcoded stub (fixed "gpt-4o-mini"/"99.9%" JSON,
# unauthenticated). Now reports what TicketCategorizer actually does, and
# is staff-only like /agents and /reports — this is internal ops data, not
# a public status page.
class Api::AiController < ApplicationController
  before_action :authenticate_user!
  before_action :require_staff!

  def status
    render json: {
      configured: TicketCategorizer.configured?,
      model: TicketCategorizer::MODEL,
      tickets_total: Ticket.count,
      tickets_ai_categorized: Ticket.where(category_source: "ai").count
    }
  end
end
