class TicketsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ticket, only: [ :show, :edit, :update, :destroy, :rate ]

  def index
    @tickets = policy_scope(Ticket).order(created_at: :desc)
    @ticket = Ticket.new
  end

  def show
    authorize @ticket
    @comments = current_user.agent? || current_user.admin? ? @ticket.comments : @ticket.comments.where(internal: false)
    @comments = @comments.order(created_at: :asc)
    @comment = @ticket.comments.build
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
    was_open = !(@ticket.resolved? || @ticket.closed?)

    if @ticket.update(ticket_params)
      notify_resolution(@ticket) if was_open && (@ticket.resolved? || @ticket.closed?)
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

  def rate
    authorize @ticket, :rate?
    if @ticket.update(satisfaction_params)
      redirect_to ticket_path(@ticket), notice: "Thanks for the feedback!"
    else
      redirect_to ticket_path(@ticket), alert: @ticket.errors.full_messages.to_sentence
    end
  end

  private

  def notify_resolution(ticket)
    return if ticket.user.nil? || ticket.user == current_user

    TicketMailer.resolved(ticket, ticket.user).deliver_later
  end

  def set_ticket
    # :rate is routed as a nested /tickets/:ticket_id/satisfaction, so its
    # id param comes in as :ticket_id rather than :id.
    @ticket = Ticket.find(params[:id] || params[:ticket_id])
  end

  def ticket_params
    permitted = params.require(:ticket).permit(:title, :description, :category)
    if current_user.agent? || current_user.admin?
      permitted.merge!(params.require(:ticket).permit(:status, :priority, :assignee_id))
    end
    permitted
  end

  def satisfaction_params
    params.require(:ticket).permit(:satisfaction_rating, :satisfaction_comment)
  end
end
