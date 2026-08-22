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

  test "due_at is set from the SLA window on create" do
    ticket = Ticket.create!(title: "Server down", user: users(:employee), priority: :critical)
    assert_in_delta 4.hours.from_now, ticket.due_at, 5.seconds
  end

  test "due_at is recomputed, anchored to now, when priority changes" do
    ticket = tickets(:one) # medium priority, due_at 3 days out per fixture
    ticket.update!(priority: :critical)
    assert_in_delta 4.hours.from_now, ticket.reload.due_at, 5.seconds
  end

  test "overdue? is true only for unresolved tickets past their due_at" do
    assert tickets(:stale_high_priority).overdue?
    refute tickets(:one).overdue? # due_at is in the future

    overdue_but_resolved = tickets(:stale_high_priority)
    overdue_but_resolved.update!(status: :resolved)
    refute overdue_but_resolved.overdue?
  end

  test "escalated_at is cleared when a resolved ticket is reopened, but not on a plain status change" do
    ticket = tickets(:stale_high_priority)
    ticket.update!(escalated_at: Time.current, status: :in_progress)
    assert_not_nil ticket.reload.escalated_at, "escalated_at should survive an open -> in_progress transition"

    ticket.update!(status: :resolved)
    ticket.update!(status: :open)
    assert_nil ticket.reload.escalated_at, "escalated_at should clear when reopening a resolved ticket"
  end
end
