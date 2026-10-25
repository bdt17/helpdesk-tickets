require "test_helper"

class TicketLimitTest < ActiveSupport::TestCase
  setup { @client = users(:client) }

  def subscribe(user, plan)
    org = Organization.create!(name: "Acme", subscription_status: "active", plan: plan)
    user.update!(organization: org, org_role: "owner")
    org
  end

  test "an unsubscribed client gets the free allowance" do
    assert_equal Plan.free_tickets_per_month, @client.monthly_ticket_limit
  end

  test "the free allowance is tunable from the environment" do
    ENV["FREE_TICKETS_PER_MONTH"] = "3"
    assert_equal 3, @client.monthly_ticket_limit
  ensure
    ENV.delete("FREE_TICKETS_PER_MONTH")
  end

  test "subscribed clients get their plan's allowance, and Priority is unlimited" do
    org = subscribe(@client, "basic")
    assert_equal 10, @client.monthly_ticket_limit
    org.update!(plan: "priority")
    assert_nil @client.reload.monthly_ticket_limit
  end

  test "a lapsed subscription falls back to the free allowance" do
    org = subscribe(@client, "business")
    org.update!(subscription_status: "canceled")
    assert_equal Plan.free_tickets_per_month, @client.reload.monthly_ticket_limit
  end

  test "staff and employees are never limited" do
    %i[employee agent admin].each { |role| assert_nil users(role).monthly_ticket_limit }
  end

  test "the free client is blocked after their free ticket, with a clear error" do
    Ticket.create!(title: "First one", user: @client)
    second = Ticket.new(title: "Second one", user: @client)
    assert_not second.valid?
    assert_match(/Upgrade your plan/, second.errors[:base].to_sentence)
  end

  test "the allowance is shared across the whole organization" do
    org = subscribe(@client, "basic")
    teammate = User.create!(email: "teammate@example.com", password: "password1234", role: :client, organization: org, org_role: "member")
    5.times { |n| Ticket.create!(title: "Owner #{n}", user: @client) }
    5.times { |n| Ticket.create!(title: "Teammate #{n}", user: teammate) }
    assert teammate.ticket_limit_reached?
    assert_not Ticket.new(title: "Eleventh", user: teammate).valid?
  end

  test "last month's tickets don't count against this month" do
    travel_to 1.month.ago do
      Ticket.create!(title: "Old", user: @client)
    end
    assert_not @client.ticket_limit_reached?
    assert Ticket.create!(title: "New month", user: @client).persisted?
  end

  test "updating an existing ticket is never blocked by the limit" do
    ticket = Ticket.create!(title: "Only one", user: @client)
    assert ticket.update(title: "Renamed")
  end
end
