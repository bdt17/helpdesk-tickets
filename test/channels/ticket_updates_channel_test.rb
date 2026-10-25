require "test_helper"

class TicketUpdatesChannelTest < ActionCable::Channel::TestCase
  test "staff subscribe and stream from ticket_updates" do
    stub_connection current_user: users(:agent)
    subscribe
    assert subscription.confirmed?
    assert_has_stream "ticket_updates"
  end

  test "clients are rejected, since the broadcast isn't scoped per-client" do
    stub_connection current_user: users(:client)
    subscribe
    assert subscription.rejected?
  end

  test "employees are rejected" do
    stub_connection current_user: users(:employee)
    subscribe
    assert subscription.rejected?
  end
end
