require "test_helper"

class TicketPolicyTest < ActiveSupport::TestCase
  setup do
    @own_ticket = tickets(:one) # belongs to users(:employee)
    @other_ticket = tickets(:two) # belongs to users(:other_employee)
  end

  test "employee can view and update their own ticket" do
    policy = TicketPolicy.new(users(:employee), @own_ticket)
    assert policy.show?
    assert policy.update?
  end

  test "employee cannot view or update someone else's ticket" do
    policy = TicketPolicy.new(users(:employee), @other_ticket)
    refute policy.show?
    refute policy.update?
  end

  test "agent can view and update any ticket" do
    policy = TicketPolicy.new(users(:agent), @other_ticket)
    assert policy.show?
    assert policy.update?
  end

  test "only admin can destroy a ticket" do
    refute TicketPolicy.new(users(:employee), @own_ticket).destroy?
    refute TicketPolicy.new(users(:agent), @own_ticket).destroy?
    assert TicketPolicy.new(users(:admin), @own_ticket).destroy?
  end

  test "scope returns only own tickets for an employee" do
    scope = TicketPolicy::Scope.new(users(:employee), Ticket).resolve
    assert_includes scope, @own_ticket
    refute_includes scope, @other_ticket
  end

  test "scope returns all tickets for an agent" do
    scope = TicketPolicy::Scope.new(users(:agent), Ticket).resolve
    assert_includes scope, @own_ticket
    assert_includes scope, @other_ticket
  end
end
