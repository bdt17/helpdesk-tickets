class DashboardController < ApplicationController
  def index
    @total_tickets = SopTicket.count
    @open_tickets = SopTicket.where.not(status: nil).count rescue 0
    @critical_tickets = SopTicket.where("priority > ?", 1).count rescue 0
  end
end
