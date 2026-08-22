class TicketUpdatesChannel < ApplicationCable::Channel
  def subscribed
    stream_from "ticket_updates"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
