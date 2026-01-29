class Analytics::DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # EVERY SINGLE template variable - bulletproof defaults
    @open_tickets    = 0
    @total_tickets   = 0
    @agents          = 0
    @recent_tickets  = []
    @ticket_stats    = { "Open" => 0, "In Progress" => 0 }
    @top_keywords    = { "Pharma" => 0, "Thomas" => 0 }  # ← FIX HERE
    
    return unless safe_data?
    
    begin
      @open_tickets    = Ticket.where(status: 'open').count
      @total_tickets   = Ticket.count
      @agents          = User.where.not(id: current_user.id).count rescue 0
      @recent_tickets  = Ticket.order(created_at: :desc).limit(10)
      
      # Stats - string keys only
      @ticket_stats    = Ticket.group(:status).count.transform_keys(&:to_s)
      
      # Keywords - safe fallback
      keyword_counts = Ticket.pluck(:title).join(' ').downcase.scan(/\w+/).tally
      @top_keywords   = keyword_counts.sort_by { |_, v| -v }.first(10).to_h
      
    rescue => e
      Rails.logger.error "Dashboard load error: #{e.message}"
      # Safe defaults persist
    end
  end

  private

  def safe_data?
    defined?(Ticket) && ActiveRecord::Base.connection.table_exists?('tickets')
  rescue
    false
  end
end
