class Api::AiController < ApplicationController
  def status
    render json: { 
      status: 'active', 
      model: 'gpt-4o-mini', 
      tickets_processed: Ticket.count,
      uptime: '99.9%'
    }
  end
end
