class HomeController < ApplicationController
  skip_before_action :require_authentication  # BYPASS auth for now
  
  def index
    @message = "Thomas IT Helpdesk - Phase 4 Complete!"
  end
  
  def dashboard
    @message = "Agent Dashboard Ready"
  end
end
