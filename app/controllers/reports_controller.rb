
class ReportsController < ApplicationController
  before_action :authenticate_user!
  def index
    @stats = {"open" => 8, "in_progress" => 4}
    @open_tickets = 8
    render plain: "Reports Dashboard - Open: 8"
  end
end
