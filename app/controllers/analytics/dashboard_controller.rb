class Analytics::DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    if ActiveRecord::Base.connection.table_exists?(:tickets)
      @open_tickets    = Ticket.where(status: "Open").count
      @total_tickets   = Ticket.count
      @recent_tickets  = Ticket.order(created_at: :desc).limit(5)
      @ticket_stats    = Ticket.group(:status).count
      @top_keywords    = Ticket.pluck(:title)
                         .join(' ')
                         .downcase
                         .scan(/\w+/)
                         .tally
                         .sort_by { |_, v| -v }
                         .first(3)
                         .to_h
    else
      @open_tickets    = 0
      @total_tickets   = 0
      @agents          = User.where(role: "agent").count rescue 0
      @recent_tickets  = []
      @ticket_stats    = {}
      @top_keywords    = {}
    end
  end
end
