class TicketsController < ApplicationController
  def index
    @tickets = Ticket.all.order(created_at: :desc).limit(10)
    @ticket = Ticket.new
  end
  
  def new
    @ticket = Ticket.new
    render :index
  end
  
  def create
    @ticket = Ticket.new(ticket_params)
    @ticket.user_id ||= 1  # Default user
    if @ticket.save
      redirect_to root_path, notice: 'Ticket created!'
    else
      @tickets = Ticket.all.order(created_at: :desc).limit(10)
      render :index
    end
  end
  
  private
  def ticket_params
    params.require(:ticket).permit(:title, :description, :status)
  end
end
