# Staff-only: the "ticket_updates" broadcast isn't scoped per-client (it
# carries ids/messages for every ticket in the system), so a client must
# not be able to subscribe to it. Hiding the banner in the layout isn't
# enough on its own - anyone signed in can open the WebSocket and send a
# subscribe command for this channel directly.
class TicketUpdatesChannel < ApplicationCable::Channel
  def subscribed
    if current_user.agent? || current_user.admin?
      stream_from "ticket_updates"
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
