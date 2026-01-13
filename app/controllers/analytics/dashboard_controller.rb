module Analytics
  class DashboardController < ApplicationController
    layout 'application'
    
    def index
      @recent_tickets = SopTicket.select(:id, :title, :status, :created_at).limit(10)
      @open_tickets = SopTicket.where(status: 'open').count
      @ticket_stats = SopTicket.group(:status).count
      @top_keywords = {}

      # Extract keywords from titles + descriptions
      all_text = SopTicket.pluck(:title, :description).flatten.compact.join(' ')
      @top_keywords = all_text.downcase.scan(/\w{3,}/).tally.sort_by { |_,v| -v }.first(10).to_h
    end
  end
end
