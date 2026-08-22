require "test_helper"

class TicketTest < ActiveSupport::TestCase
  test "belongs to a user" do
    ticket = tickets(:one)
    assert_equal users(:employee), ticket.user
  end

  test "can be created without a user" do
    ticket = Ticket.new(title: "Anonymous report", status: "open")
    assert ticket.valid?
  end
end
