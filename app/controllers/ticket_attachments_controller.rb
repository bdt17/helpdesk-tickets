# Active Storage's own blob-serving routes (rails_blob_path and friends)
# don't check this app's authorization at all - just that the signed blob
# ID is valid - so linking to them directly from a ticket page would let
# anyone who gets hold of that URL read the file, bypassing TicketPolicy
# entirely. This controller puts our own authorization check in front and
# streams the bytes itself, rather than redirecting to rails_blob_path:
# that URL embeds a signed blob id that never expires, so once a user had
# been redirected to it once (a since-removed teammate, a shared browser
# history, a forwarded link) it kept working forever with no login at all.
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

    send_data attachment.download,
              filename: attachment.filename.to_s,
              type: attachment.content_type,
              disposition: disposition
  end
end
