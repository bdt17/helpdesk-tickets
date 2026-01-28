class Analytics::DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    if current_user.agent? || current_user.admin?
      # AGENT sees ALL tickets
      @open_tickets = Ticket.where(status: 'open').count      # 8
      @total_tickets = Ticket.count                           # 10
      @recent_tickets = Ticket.order(created_at: :desc).limit(10)
      @stats = Ticket.group(:status).count                    # Open:8, In Progress:4
      @keywords = Ticket.pluck(:title).join(' ').downcase.scan(/\w+/).tally.sort_by { |_,v| -v }.first(6)
    else
      # CUSTOMER sees only their tickets
      @open_tickets = current_user.tickets.where(status: 'open').count || 0
      @total_tickets = current_user.tickets.count || 0
      @recent_tickets = current_user.tickets.order(created_at: :desc).limit(10)
      @stats = current_user.tickets.group(:status).count
      @keywords = []
    end
  end
end
