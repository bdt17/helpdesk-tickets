class TicketsController < ApplicationController
  before_action :authenticate_user!, except: [:new, :create]
  
  def index
    @tickets = Ticket.all.order(created_at: :desc)
  end
  
  def show
    @ticket = Ticket.find(params[:id])
  end
  
  def new
    @ticket = Ticket.new
  end
  
  def create
    @ticket = Ticket.new(ticket_params)
    @ticket.email = current_user&.email if user_signed_in?
    
    if @ticket.save
      redirect_to root_path, notice: "Ticket created!"
    else
      render :new
    end
  end
  
  private
  
  def ticket_params
    params.require(:ticket).permit(:title, :description, :email, :status, :project_id)
  end
end
