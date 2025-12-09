class TicketsController < ApplicationController
  def index
    @tickets = Ticket.all.order(updated_at: :desc)
  end

  def client_dashboard
    @tickets = Ticket.all.order(updated_at: :desc)
  end

  def tech_dashboard
    @tickets_by_status = Ticket.all.group_by { |t| t.status || 'new' }
  end
end
def tech_dashboard
  @tickets_by_status = Ticket.all.group_by { |t| t.status || 'new' }
  @knowledge_bases = KnowledgeBase.where(category: 'networking').limit(5)
end
