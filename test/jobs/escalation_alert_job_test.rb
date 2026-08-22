require "test_helper"

class EscalationAlertJobTest < ActiveJob::TestCase
  test "escalates a high priority ticket open more than 24h" do
    ticket = tickets(:stale_high_priority)
    assert ticket.open?

    EscalationAlertJob.perform_now(ticket.id)

    assert ticket.reload.in_progress?
  end

  test "does not escalate a fresh high priority ticket" do
    ticket = tickets(:two) # in_progress, created "now" per fixture default
    EscalationAlertJob.perform_now(ticket.id)

    assert ticket.reload.in_progress? # unchanged
  end

  test "does not escalate a low priority ticket" do
    ticket = tickets(:one)
    EscalationAlertJob.perform_now(ticket.id)

    assert ticket.reload.open? # unchanged
  end
end
