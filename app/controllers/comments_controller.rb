class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ticket

  def create
    @comment = @ticket.comments.build(comment_params)
    authorize @comment
    @comment.user = current_user

    if @comment.save
      TicketNotifier.comment_posted(@comment, current_user)
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
end
