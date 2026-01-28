 class TicketsController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    if current_user.agent? || current_user.admin?
      @open_tickets = Ticket.where(status: 'open').count
      @total_tickets = Ticket.count
      @recent_tickets = Ticket.order(created_at: :desc).limit(10)
      @stats = Ticket.group(:status).count
    else
      @open_tickets = current_user.tickets.where(status: 'open').count
      @total_tickets = current_user.tickets.count
      @recent_tickets = current_user.tickets.order(created_at: :desc).limit(10)
      @stats = current_user.tickets.group(:status).count
    end
  end

  # Your existing CRUD methods...
end

