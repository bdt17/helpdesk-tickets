class TicketsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ticket, only: [:show, :edit, :update, :destroy]

  def index
    @tickets = policy_scope(Ticket).order(created_at: :desc)
    @ticket = Ticket.new
  end

  def show
    authorize @ticket
  end

  def new
    @ticket = Ticket.new
    authorize @ticket
  end

  def create
    @ticket = current_user.tickets.build(ticket_params)
    authorize @ticket

    if @ticket.save
      redirect_to tickets_path, notice: "Ticket created!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @ticket
  end

  def update
    authorize @ticket
    if @ticket.update(ticket_params)
      redirect_to tickets_path, notice: "Updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @ticket
    @ticket.destroy
    redirect_to tickets_path, notice: "Deleted!"
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:id])
  end

  def ticket_params
    permitted = params.require(:ticket).permit(:title, :description, :category)
    if current_user.agent? || current_user.admin?
      permitted.merge!(params.require(:ticket).permit(:status, :priority, :assignee_id))
    end
    permitted
  end
end
