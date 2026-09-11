require "test_helper"

class TicketCategorizationJobTest < ActiveJob::TestCase
  test "sets category and category_source when Claude suggests one" do
    ticket = tickets(:one)
    ticket.update_columns(category: nil, category_source: "manual")

    TicketCategorizer.stub(:call, "network") do
      TicketCategorizationJob.perform_now(ticket.id)
    end

    ticket.reload
    assert_equal "network", ticket.category
    assert_equal "ai", ticket.category_source
  end

  test "leaves the ticket alone when TicketCategorizer returns nil" do
    ticket = tickets(:one)
    ticket.update_columns(category: nil, category_source: "manual")

    TicketCategorizer.stub(:call, nil) do
      TicketCategorizationJob.perform_now(ticket.id)
    end

    ticket.reload
    assert_nil ticket.category
    assert_equal "manual", ticket.category_source
  end

  test "does not overwrite a category the client already picked" do
    ticket = tickets(:one) # fixture already has category: hardware

    TicketCategorizer.stub(:call, "network") do
      TicketCategorizationJob.perform_now(ticket.id)
    end

    assert_equal "hardware", ticket.reload.category
  end

  test "does nothing for a ticket that no longer exists" do
    assert_nothing_raised do
      TicketCategorizationJob.perform_now(-1)
    end
  end
end
