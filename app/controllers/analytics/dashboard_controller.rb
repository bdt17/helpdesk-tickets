class Analytics::DashboardController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @open_tickets    = 8
    @total_tickets   = 10  
    @agents          = 1
    @recent_tickets  = [
      {"id" => 1, "title" => "Pharma Transport - missing implementations", "status" => "Open", "created" => "15 days ago"},
      {"id" => 2, "title" => "Thomas IT drones IT functions", "status" => "Open", "created" => "13 days ago"},
      {"id" => 3, "title" => "3-D printing optimization", "status" => "In Progress", "created" => "15 days ago"}
    ]
    @ticket_stats    = {"Open" => 8, "In Progress" => 2}
    @top_keywords    = {"Pharma" => 15, "Thomas" => 15, "Drones" => 15}
  end
end
