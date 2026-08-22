require "test_helper"

class TicketEscalationSweepJobTest < ActiveJob::TestCase
  test "enqueues EscalationAlertJob only for overdue, not-yet-escalated tickets" do
    TicketEscalationSweepJob.perform_now
    enqueued_ticket_ids = enqueued_jobs.select { |j| j[:job] == EscalationAlertJob }.map { |j| j[:args].first }

    assert_includes enqueued_ticket_ids, tickets(:stale_high_priority).id
    assert_not_includes enqueued_ticket_ids, tickets(:one).id # not overdue
    assert_not_includes enqueued_ticket_ids, tickets(:two).id # not overdue
  end

  test "does not enqueue anything for an already-escalated overdue ticket" do
    tickets(:stale_high_priority).update_columns(escalated_at: 1.hour.ago)

    TicketEscalationSweepJob.perform_now
    enqueued_ticket_ids = enqueued_jobs.select { |j| j[:job] == EscalationAlertJob }.map { |j| j[:args].first }

    assert_not_includes enqueued_ticket_ids, tickets(:stale_high_priority).id
  end
end
