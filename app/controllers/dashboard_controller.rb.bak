class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @total_tickets = Ticket.count || 0
    @critical_tickets = Ticket.where(priority: 'critical').count || 0
    @network_tickets = Ticket.where("title ILIKE ?", '%network%').count || 0
    @open_tickets = Ticket.where(status: 'open').count || 0
    @recent_tickets = Ticket.order(created_at: :desc).limit(10).to_a || []
  end
end
