class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    if current_user.agent? || current_user.admin?
      @open_tickets = Ticket.where(status: 'open').count || 0
      @total_tickets = Ticket.count || 0
      @recent_tickets = Ticket.order(created_at: :desc).limit(10) || []  # ← FIX: default empty array
      @stats = Ticket.group(:status).count || {}
      @keywords = Ticket.pluck(:title).join(' ').downcase.scan(/\w{3,}/).tally.sort_by { |_,v| -v }.first(6) || []
    else
      @open_tickets = current_user.tickets.where(status: 'open').count || 0
      @total_tickets = current_user.tickets.count || 0
      @recent_tickets = current_user.tickets.order(created_at: :desc).limit(10) || []  # ← FIX
      @stats = current_user.tickets.group(:status).count || {}
      @keywords = []
    end
  end
end
