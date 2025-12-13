class TechsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @tickets = Ticket.all.order(created_at: :desc)
  end
  
  def ping
    # Simple ping simulation - real implementation later
    @ping_result = "PING google.com (142.250.190.78): 64 bytes from 142.250.190.78: icmp_seq=0 ttl=117 time=12.3 ms"
    render partial: 'ping_result'
  end
end
