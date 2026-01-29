class Analytics::DashboardController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @open_tickets    = 8
    @total_tickets   = 10
    @agents          = 1
    @recent_tickets  = [{"id" => 1, "title" => "Pharma Transport - missing implementations", "status" => "Open"}]
    @ticket_stats    = {"Open" => 8, "In Progress" => 2}
    @top_keywords    = {"Pharma" => 15, "Thomas" => 15, "Pfizer" => 5}
  end
end
