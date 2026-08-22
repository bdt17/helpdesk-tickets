require "test_helper"

class TicketUpdatesChannelTest < ActionCable::Channel::TestCase
  test "subscribes and streams from ticket_updates" do
    subscribe
    assert subscription.confirmed?
    assert_has_stream "ticket_updates"
  end
end
