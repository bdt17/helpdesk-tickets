# Active Storage's own blob-serving routes (rails_blob_path and friends)
# don't check this app's authorization at all - just that the signed blob
# ID is valid - so linking to them directly from a ticket page would let
# anyone who gets hold of that URL read the file, bypassing TicketPolicy
# entirely. This controller puts our own authorization check in front:
# only redirect to the real (signed, otherwise-unauthenticated) file URL
# once Pundit has confirmed this user can see the ticket it belongs to.
class TicketAttachmentsController < ApplicationController
  before_action :authenticate_user!

  def show
    ticket = Ticket.find(params[:ticket_id])
    authorize ticket, :show?

    # Scoped through the ticket's own association, not
    # ActiveStorage::Attachment.find(params[:id]) directly, so an
    # attachment id that belongs to some other ticket 404s here rather
    # than leaking whether it exists.
    attachment = ticket.attachments.find(params[:id])
    disposition = attachment.content_type.start_with?("image/") ? "inline" : "attachment"

    redirect_to rails_blob_path(attachment, disposition: disposition)
  end
end
