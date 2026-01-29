class Analytics::DashboardController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @open_tickets = 0
    @total_tickets = 10
    @recent_tickets = []
    @ticket_stats = {"Open" => 8, "In Progress" => 2}
    @top_keywords = {"Pharma" => 15, "Thomas" => 15, "Pfizer" => 5}
  end
end
