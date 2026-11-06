require "test_helper"

class TimeEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ticket = tickets(:one)
  end

  test "staff log time on a ticket and see the total" do
    sign_in users(:agent)
    post ticket_time_entries_url(@ticket), params: { time_entry: { minutes: 90, note: "Replaced toner" } }
    assert_redirected_to ticket_url(@ticket)
    assert_equal "Logged 1h 30m.", flash[:notice]

    entry = @ticket.time_entries.last
    assert_equal users(:agent), entry.user
    assert_equal Date.current, entry.worked_on

    get ticket_url(@ticket)
    assert_select "h2", text: /Time spent/
    assert_match "Replaced toner", response.body
  end

  test "invalid minutes are rejected" do
    sign_in users(:agent)
    assert_no_difference "TimeEntry.count" do
      post ticket_time_entries_url(@ticket), params: { time_entry: { minutes: 0 } }
      post ticket_time_entries_url(@ticket), params: { time_entry: { minutes: 5000 } }
    end
  end

  test "clients can't log time or see it" do
    TimeEntry.create!(ticket: @ticket, user: users(:agent), minutes: 30, worked_on: Date.current, note: "internal detail")
    sign_in @ticket.user
    assert_no_difference "TimeEntry.count" do
      post ticket_time_entries_url(@ticket), params: { time_entry: { minutes: 10 } }
    end
    get ticket_url(@ticket)
    assert_no_match "Time spent", response.body
    assert_no_match "internal detail", response.body
  end

  test "staff remove only their own entries; admins can remove any" do
    entry = TimeEntry.create!(ticket: @ticket, user: users(:agent), minutes: 30, worked_on: Date.current)
    sign_in User.create!(email: "agent2@example.com", password: "password1234", role: :agent)
    assert_no_difference "TimeEntry.count" do
      delete ticket_time_entry_url(@ticket, entry)
    end

    sign_in users(:admin)
    assert_difference "TimeEntry.count", -1 do
      delete ticket_time_entry_url(@ticket, entry)
    end
  end

  test "format_minutes" do
    assert_equal "45m", TimeEntry.format_minutes(45)
    assert_equal "2h", TimeEntry.format_minutes(120)
    assert_equal "1h 5m", TimeEntry.format_minutes(65)
    assert_equal "0m", TimeEntry.format_minutes(0)
  end
end
