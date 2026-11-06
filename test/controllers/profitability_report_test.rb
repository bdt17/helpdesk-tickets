require "test_helper"

class ProfitabilityReportTest < ActionDispatch::IntegrationTest
  setup do
    @org = Organization.create!(name: "Busy Co", stripe_customer_id: "cus_busy", subscription_status: "active", plan: "basic")
    @client = users(:client)
    @client.update!(organization: @org, org_role: "owner")
    @ticket = Ticket.create!(title: "Help", user: @client)
  end

  test "admins see revenue per hour for each client this month" do
    TimeEntry.create!(ticket: @ticket, user: users(:agent), minutes: 120, worked_on: Date.current)
    TimeEntry.create!(ticket: @ticket, user: users(:agent), minutes: 600, worked_on: 2.months.ago.to_date)
    sign_in users(:admin)
    get reports_index_url

    assert_select "tr.profit-row", text: /Busy Co/ do |row|
      assert_match "2h", row.text   # the 10h from two months ago is excluded
      assert_match "$25", row.text  # $49 basic / 2h, rounded
    end
  end

  test "STAFF_HOURLY_COST adds estimated profit" do
    ENV["STAFF_HOURLY_COST"] = "40"
    TimeEntry.create!(ticket: @ticket, user: users(:agent), minutes: 120, worked_on: Date.current)
    sign_in users(:admin)
    get reports_index_url
    assert_select "th", text: "Est. profit"
    assert_select "tr.profit-row td.text-danger", text: "-$31" # 49 - 2 * 40
  ensure
    ENV.delete("STAFF_HOURLY_COST")
  end

  test "agents don't see the profitability section" do
    sign_in users(:agent)
    get reports_index_url
    assert_select "#profitability", count: 0
  end

  test "the monthly client report includes technician time" do
    TimeEntry.create!(ticket: @ticket, user: users(:agent), minutes: 75, worked_on: Date.current)
    report = MonthlyClientReport.new(@org, Date.current)
    assert_equal 75, report.stats[:technician_minutes]
  end
end
