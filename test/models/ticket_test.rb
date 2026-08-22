require "test_helper"

class TicketTest < ActiveSupport::TestCase
  test "belongs to a user" do
    ticket = tickets(:one)
    assert_equal users(:employee), ticket.user
  end

  test "requires a user" do
    ticket = Ticket.new(title: "Anonymous report")
    refute ticket.valid?
    assert_includes ticket.errors[:user], "must exist"
  end

  test "status and priority default" do
    ticket = Ticket.create!(title: "New issue", user: users(:employee))
    assert ticket.open?
    assert ticket.medium?
  end

  test "category must be one of the canonical values" do
    ticket = Ticket.new(title: "Broken laptop", user: users(:employee), category: "bogus")
    refute ticket.valid?
    assert_includes ticket.errors[:category], "is not included in the list"
  end

  test "category can be blank" do
    ticket = Ticket.new(title: "Broken laptop", user: users(:employee), category: nil)
    assert ticket.valid?
  end

  test "resolved_at is stamped when status moves to resolved and cleared when reopened" do
    ticket = tickets(:one)
    assert_nil ticket.resolved_at

    ticket.update!(status: :resolved)
    assert_not_nil ticket.reload.resolved_at

    ticket.update!(status: :open)
    assert_nil ticket.reload.resolved_at
  end

  test "can have an assignee" do
    ticket = tickets(:two)
    assert_equal users(:agent), ticket.assignee
  end
end
