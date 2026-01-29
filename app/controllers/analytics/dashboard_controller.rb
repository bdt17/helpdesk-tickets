class Analytics::DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @open_tickets = tickets_exist? ? Ticket.open.count : 0
    @total_tickets = tickets_exist? ? Ticket.count : 0
    @agents = User.where.not(id: current_user.id).count
  rescue ActiveRecord::StatementInvalid
    @open_tickets = @total_tickets = @agents = 0
  end

  private

  def tickets_exist?
    ActiveRecord::Base.connection.table_exists?('tickets')
  end
end
