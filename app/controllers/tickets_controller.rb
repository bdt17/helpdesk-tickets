class TicketsController < ApplicationController
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

