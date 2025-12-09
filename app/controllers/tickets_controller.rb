class TicketsController < ApplicationController

# Custom scope for tech-assigned tickets
scope :assigned_to, ->(tech) { where(tech_id: tech.id) }



def client_dashboard
  @tickets = current_user.tickets # Assumes client submits tickets
    .includes(:tech, :ticket_updates)
    .order(created_at: :desc)
end

# app/controllers/tickets_controller.rb
def tech_dashboard
  @tickets_by_status = Ticket.assigned_to(current_user) # Custom scope below
    .group_by(&:status)
end


  def index
    @tickets = Ticket.all
  end

  def new
    @ticket = Ticket.new
  end

  def create
    @ticket = Ticket.new(ticket_params)
    @ticket.status = 'open'
    if @ticket.save
      TicketMailer.new_ticket(@ticket).deliver_now
      redirect_to tickets_path, notice: "Ticket created and emailed!"
    else
      render :new
    end
  end

  private
  def ticket_params
    params.require(:ticket).permit(:title, :description, :email)
  end
end

