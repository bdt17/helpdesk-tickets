class Analytics::DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @open_tickets = 0
    @total_tickets = 0
    @agents = 0
    @recent_tickets = []
    
    # Safe ticket queries only if table exists
    if defined?(Ticket) && table_exists?
      @open_tickets = Ticket.where(status: 'open').count rescue 0
      @total_tickets = Ticket.count rescue 0
      @recent_tickets = Ticket.last(10) rescue []
    end
  rescue
    # Zero everything on any error
    @open_tickets = @total_tickets = @agents = 0
    @recent_tickets = []
  end

  private

  def table_exists?
    return false unless defined?(Ticket)
    ActiveRecord::Base.connection.table_exists?('tickets')
  rescue
    false
  end
end
