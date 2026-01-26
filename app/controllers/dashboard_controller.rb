class DashboardController < ApplicationController
  def index
    @open_tickets = SopTicket.where.not(status: nil).count
    @total_tickets = SopTicket.count
    @critical_tickets = SopTicket.where("priority >= ?", 3).count rescue 0
  end
end
