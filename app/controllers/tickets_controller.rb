class TicketsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ticket, only: [:show, :edit, :update, :destroy]

  def index
    @tickets = current_user.agent? || current_user.admin? ? 
               Ticket.all : current_user.tickets
    @ticket = Ticket.new
  end

  def dashboard
    if current_user.agent? || current_user.admin?
      @open_tickets = Ticket.where(status: 'open').count
      @total_tickets = Ticket.count
      @recent_tickets = Ticket.order(created_at: :desc).limit(10)
      @stats = Ticket.group(:status).count
    else
      @open_tickets = current_user.tickets.where(status: 'open').count
      @total_tickets = current_user.tickets.count
      @recent_tickets = current_user.tickets.order(created_at: :desc).limit(10)
      @stats = current_user.tickets.group(:status).count
    end
  end

  def show; end

  def new
    @ticket = Ticket.new
  end

  def create
    @ticket = Ticket.new(ticket_params)
    @ticket.assignee = current_user if current_user.agent?
    
    if @ticket.save
      redirect_to tickets_path, notice: 'Ticket created!'
    else
      render :new
    end
  end

  def edit; end

  def update
    if @ticket.update(ticket_params)
      redirect_to tickets_path, notice: 'Updated!'
    else
      render :edit
    end
  end

  def destroy
    @ticket.destroy
    redirect_to tickets_path, notice: 'Deleted!'
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:id])
  end

  def ticket_params
    params.require(:ticket).permit(:title, :description, :status, :priority, :category)
  end
end
