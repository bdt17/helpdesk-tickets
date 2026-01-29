class Analytics::DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # BULLETPROOF - ALL variables always set
    @open_tickets    = 0
    @total_tickets   = 0
    @agents          = 0
    @recent_tickets  = []
    @ticket_stats    = { "Open" => 0, "In Progress" => 0 }
    
    # Safe ticket loading ONLY if everything works
    begin
      return unless defined?(Ticket) && table_exists?
      
      @open_tickets = Ticket.open.count
      @total_tickets = Ticket.count
      @recent_tickets = Ticket.last(10)
      
      # CRITICAL FIX: String keys + titleize-safe
      raw_stats = Ticket.group(:status).count
      @ticket_stats = raw_stats.transform_keys { |k| k.to_s.titleize }
      
    rescue => e
      Rails.logger.error "Dashboard error: #{e.message}"
      # Keep safe defaults
    end
  end

  private
  
  def table_exists?
    ActiveRecord::Base.connection.table_exists?('tickets')
  rescue
    false
  end
end
