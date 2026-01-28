class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    if current_user.agent? || current_user.admin?
      # Agent/Admin sees ALL tickets
      @total_tickets = Ticket.count || 0
      @critical_tickets = Ticket.where(priority: 'critical').count || 0
      @network_tickets = Ticket.where("title LIKE ?", '%network%').count || 0
      @open_tickets = Ticket.where(status: 'open').count || 0
      @recent_tickets = Ticket.order(created_at: :desc).limit(10) || []
    else
      # Customer sees only THEIR tickets
      @total_tickets = current_user.tickets.count || 0
      @critical_tickets = current_user.tickets.where(priority: 'critical').count || 0
      @network_tickets = current_user.tickets.where("title LIKE ?", '%network%').count || 0
      @open_tickets = current_user.tickets.where(status: 'open').count || 0
      @recent_tickets = current_user.tickets.order(created_at: :desc).limit(10) || []
    end
  end
end
