class HomeController < ApplicationController
  # skip_before_action :require_authentication  # Disabled - callback undefined
  
  def index
    @message = "Thomas IT Helpdesk - Phase 4 Complete!"
  end
  
  def dashboard
    @message = "Agent Dashboard Ready"
  end
end
