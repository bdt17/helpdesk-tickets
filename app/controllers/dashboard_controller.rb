class DashboardController < ApplicationController
  def index
    @total_tickets = SopTicket.count
    @network_tickets = SopTicket.where("title LIKE ? OR description LIKE ?", '%Cisco%', '%HP%').count
    @open_tickets = SopTicket.open.count
    @critical_tickets = SopTicket.critical.count
    @recent_network = SopTicket.where("title LIKE ?", '%Cisco% OR title LIKE ?', '%HP%').order(created_at: :desc).limit(5)
    @devices = Device.count
    @sites = Site.count
  end
end
