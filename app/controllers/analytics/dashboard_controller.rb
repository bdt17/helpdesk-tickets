class Analytics::DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # ALWAYS set ALL instance variables with safe defaults
    @open_tickets = 0
    @total_tickets = 0
    @agents = 0
    @recent_tickets = []
    @ticket_stats = { open: 0, 'in_progress' => 0 }  # ← FIX HERE
    
    begin
      return unless table_exists?
      
      @open_tickets = Ticket.where(status: 'open').count
      @total_tickets = Ticket.count
      @recent_tickets = Ticket.order(created_at: :desc).limit(10)
      @ticket_stats = Ticket.group(:status).count  # Hash like { "open" => 5 }
      
    rescue 
      # Keep safe defaults on ANY error
    end
  end

  private

  def table_exists?
    ActiveRecord::Base.connection.table_exists?('tickets') rescue false
  end
end
