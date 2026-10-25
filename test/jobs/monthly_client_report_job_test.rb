require "test_helper"

class MonthlyClientReportJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @org = Organization.create!(name: "Acme", subscription_status: "active", plan: "business")
    @owner = users(:client)
    @owner.update!(organization: @org, org_role: "owner")
    @october = Date.new(2026, 10, 1)
  end

  def ticket_in_october(**attrs)
    travel_to Time.zone.local(2026, 10, 5, 9) do
      Ticket.create!(title: "Issue", user: @owner, priority: :high, **attrs)
    end
  end

  test "computes last month's numbers for the organization" do
    fast = ticket_in_october(category: "network")
    travel_to(Time.zone.local(2026, 10, 5, 13)) { fast.update!(status: :resolved, satisfaction_rating: 5) } # 4h, within 24h SLA
    slow = ticket_in_october(category: "network")
    travel_to(Time.zone.local(2026, 10, 7, 9)) { slow.update!(status: :resolved, satisfaction_rating: 3) }  # 48h, missed SLA
    ticket_in_october(category: "hardware") # still open
    travel_to(Time.zone.local(2026, 9, 20)) { Ticket.create!(title: "September", user: @owner) }
    Ticket.create!(title: "Someone else's", user: users(:employee))

    stats = MonthlyClientReport.new(@org, @october).stats

    assert_equal "October 2026", stats[:month_name]
    assert_equal 3, stats[:filed]
    assert_equal 2, stats[:resolved]
    assert_equal 26.0, stats[:avg_resolution_hours]
    assert_equal 50, stats[:sla_met_percent]
    assert_equal 4.0, stats[:csat_average]
    assert_equal 2, stats[:still_open] # October's open one + September's
    assert_equal({ "network" => 2, "hardware" => 1 }, stats[:by_category])
  end

  test "emails each paying organization's owner once per month" do
    Organization.create!(name: "Free", subscription_status: nil)
    Organization.create!(name: "Canceled", subscription_status: "canceled")

    assert_enqueued_emails 1 do
      MonthlyClientReportJob.perform_now(@october)
    end
    assert_equal @october, @org.reload.monthly_report_sent_on

    assert_no_enqueued_emails do
      MonthlyClientReportJob.perform_now(@october) # retried / re-run
    end

    assert_enqueued_emails 1 do
      MonthlyClientReportJob.perform_now(Date.new(2026, 11, 1))
    end
  end

  test "skips an organization with no owner" do
    @owner.update!(org_role: "member")
    assert_no_enqueued_emails { MonthlyClientReportJob.perform_now(@october) }
  end

  test "the email leads with what was resolved" do
    resolved = ticket_in_october
    travel_to(Time.zone.local(2026, 10, 5, 12)) { resolved.update!(status: :resolved) }
    stats = MonthlyClientReport.new(@org, @october).stats
    mail = ClientReportMailer.monthly(@org, @owner, stats)

    assert_equal [ @owner.email ], mail.to
    assert_equal "October 2026: we resolved 1 issue for Acme", mail.subject
    assert_match "Tickets resolved:       1", mail.text_part.body.to_s
    assert_match "Resolved within SLA:    100%", mail.text_part.body.to_s
    assert_match "/tickets", mail.html_part.body.to_s
  end

  test "a quiet month still sends a reassuring summary" do
    stats = MonthlyClientReport.new(@org, @october).stats
    mail = ClientReportMailer.monthly(@org, @owner, stats)

    assert_equal "October 2026: your Thomas IT support summary", mail.subject
    assert_match "A quiet month", mail.text_part.body.to_s
    assert_no_match "Average time to fix", mail.text_part.body.to_s
  end

  test "is scheduled for the 1st of each month in production" do
    config = YAML.load_file(Rails.root.join("config/recurring.yml"))
    assert_equal "MonthlyClientReportJob", config.dig("production", "monthly_client_report", "class")
  end
end
