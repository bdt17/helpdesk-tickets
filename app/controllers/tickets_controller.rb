class TicketsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ticket, only: [ :show, :edit, :update, :destroy, :rate ]

  def index
    @tickets = filtered_tickets(policy_scope(Ticket)).order(created_at: :desc)
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
    # Attached separately from the rest of ticket_params, and always via
    # .attach (append), never mass-assignment (which would replace every
    # existing attachment) - see attach_uploaded_files. Short-circuits
    # before touching the rest of ticket_params if the attachment itself
    # was rejected, so nothing about a bad upload gets a false "Updated!".
    if attach_uploaded_files(@ticket) && @ticket.update(ticket_params.except(:attachments))
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

  # has_many_attached's normal writer (mass-assignment via ticket_params)
  # REPLACES the whole attachment set, which is exactly right for #create
  # (a brand-new ticket has nothing to replace) but wrong for #update -
  # uploading one more screenshot would silently delete every earlier one.
  # .attach always appends instead, regardless of how many are already there.
  #
  # Returns whether the attach actually succeeded. For an already-persisted,
  # otherwise-unchanged record (always true for @ticket at this point in
  # #update - this runs before ticket_params touches anything else),
  # Attached::Many#attach calls record.save internally, which runs this
  # model's own validations (including attachments_are_valid) before
  # anything is written - an invalid file (wrong type, too big, too many)
  # is never persisted at all, it just leaves ticket.errors populated and
  # returns without raising. Checking that here is what stops a rejected
  # upload from silently vanishing behind a false "Updated!".
  def attach_uploaded_files(ticket)
    files = Array(params.dig(:ticket, :attachments)).reject(&:blank?)
    return true if files.empty?

    ticket.attachments.attach(files)
    ticket.errors.empty?
  end

  # Filters are applied on top of policy_scope, never instead of it - a
  # client filtering by status still only ever sees their own
  # organization's tickets, since `scope` here is already the
  # authorized set.
  def filtered_tickets(scope)
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(priority: params[:priority]) if params[:priority].present?
    scope = scope.where(category: params[:category]) if params[:category].present?
    scope = scope.where(assignee_id: params[:assignee_id]) if params[:assignee_id].present?

    if params[:q].present?
      # LOWER(...) LIKE rather than ILIKE/case-insensitive collation
      # tricks, since this app runs SQLite in dev/test and PostgreSQL in
      # production and this is the one pattern that behaves the same on
      # both.
      term = "%#{params[:q].downcase}%"
      scope = scope.where("LOWER(title) LIKE :term OR LOWER(description) LIKE :term", term: term)
    end

    scope
  end

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
    permitted = params.require(:ticket).permit(:title, :description, :category, attachments: [])
    if current_user.agent? || current_user.admin?
      permitted.merge!(params.require(:ticket).permit(:status, :priority, :assignee_id))
    end
    permitted
  end

  def satisfaction_params
    params.require(:ticket).permit(:satisfaction_rating, :satisfaction_comment)
  end
end
