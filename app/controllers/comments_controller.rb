class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ticket

  def create
    @comment = @ticket.comments.build(comment_params)
    authorize @comment
    @comment.user = current_user

    if @comment.save
      notify_recipients(@comment)
      redirect_to ticket_path(@ticket), notice: "Comment added."
    else
      redirect_to ticket_path(@ticket), alert: @comment.errors.full_messages.to_sentence
    end
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:ticket_id])
  end

  def comment_params
    permitted = params.require(:comment).permit(:body)
    if current_user.agent? || current_user.admin?
      permitted.merge!(params.require(:comment).permit(:internal))
    end
    permitted
  end

  def notify_recipients(comment)
    recipients(comment).each do |recipient|
      TicketMailer.comment_posted(comment, recipient).deliver_later
    end
  end

  def recipients(comment)
    people = comment.internal? ? [ @ticket.assignee ] : [ @ticket.user, @ticket.assignee ]
    people.compact.uniq - [ current_user ]
  end
end
