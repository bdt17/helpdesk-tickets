require "test_helper"

class ExtraTicketCreditTest < ActiveSupport::TestCase
  setup do
    @org = Organization.create!(name: "Acme", stripe_customer_id: "cus_1")
    @client = users(:client)
    @client.update!(organization: @org, org_role: "owner")
    Ticket.create!(title: "Free one", user: @client) # uses the 1 free ticket
  end

  test "past the allowance, a ticket uses one purchased credit" do
    @org.update!(extra_ticket_credits: 2)
    assert_not @client.reload.ticket_limit_reached?

    Ticket.create!(title: "Paid extra", user: @client)
    assert_equal 1, @org.reload.extra_ticket_credits
  end

  test "with no credits left, filing is blocked" do
    @org.update!(extra_ticket_credits: 1)
    Ticket.create!(title: "Last credit", user: @client)
    assert @client.reload.ticket_limit_reached?
    assert_not Ticket.new(title: "One too many", user: @client).save
    assert_equal 0, @org.reload.extra_ticket_credits
  end

  test "credits aren't spent while still within the allowance" do
    travel_to 1.month.from_now.beginning_of_month + 1.day do
      @org.update!(extra_ticket_credits: 3)
      Ticket.create!(title: "New month, free again", user: @client)
      assert_equal 3, @org.reload.extra_ticket_credits
    end
  end

  test "a stale in-memory count can't spend a credit twice" do
    @org.update!(extra_ticket_credits: 1)
    first = Ticket.new(title: "A", user: User.find(@client.id))
    second = Ticket.new(title: "B", user: User.find(@client.id))
    assert first.valid? && second.valid? # both saw 1 credit
    assert first.save
    assert_not second.save
    assert_equal 0, @org.reload.extra_ticket_credits
  end
end
