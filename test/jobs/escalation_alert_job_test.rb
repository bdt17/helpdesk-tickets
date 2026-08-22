require "test_helper"

class EscalationAlertJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper
  test "escalates an overdue ticket: bumps status, stamps escalated_at, emails the assignee" do
    ticket = tickets(:two) # in_progress, overdue (due_at 12h from... wait, adjust below), assignee: agent
    ticket.update_columns(due_at: 1.hour.ago, status: "open")

    assert_emails 1 do
      EscalationAlertJob.perform_now(ticket.id)
    end

    ticket.reload
    assert ticket.in_progress?
    assert_not_nil ticket.escalated_at
    assert_equal [users(:agent).email], ActionMailer::Base.deliveries.last.to
  end

  test "notifies every agent/admin when the ticket has no assignee" do
    ticket = tickets(:stale_high_priority) # overdue, no assignee

    assert_emails User.agent.or(User.admin).count do
      EscalationAlertJob.perform_now(ticket.id)
    end
  end

  test "does not escalate a ticket that is not overdue" do
    ticket = tickets(:one)
    assert_no_emails do
      EscalationAlertJob.perform_now(ticket.id)
    end
    refute ticket.reload.escalated_at
  end

  test "does not re-escalate (or re-notify) an already-escalated ticket" do
    ticket = tickets(:stale_high_priority)
    ticket.update_columns(escalated_at: 1.hour.ago)

    assert_no_emails do
      EscalationAlertJob.perform_now(ticket.id)
    end
  end

  test "does not escalate an overdue ticket that has since been resolved" do
    ticket = tickets(:stale_high_priority)
    ticket.update!(status: :resolved)

    assert_no_emails do
      EscalationAlertJob.perform_now(ticket.id)
    end
  end
end
