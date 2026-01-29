class Analytics::DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # ALL instance variables - bulletproof defaults
    @open_tickets = 0
    @total_tickets = 0
    @agents = 0
    @recent_tickets = []
    @ticket_stats = { 'open' => 0, 'in_progress' => 0 }  # STRING keys!
    
    return unless safe_ticket_query?
    
    @open_tickets = Ticket.where(status: 'open').count rescue 0
    @total_tickets = Ticket.count rescue 0
    @recent_tickets = Ticket.order(created_at: :desc).limit(10) rescue []
    @ticket_stats = Ticket.group(:status).count.transform_keys(&:to_s) rescue @ticket_stats
  end

  private

  def safe_ticket_query?
    return false unless defined?(Ticket)
    ActiveRecord::Base.connection.table_exists?('tickets') rescue false
  end
end
