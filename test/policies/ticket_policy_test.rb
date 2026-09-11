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

  test "owner can rate their own resolved ticket, but not while it's still open" do
    refute TicketPolicy.new(users(:employee), @own_ticket).rate?

    @own_ticket.update!(status: :resolved)
    assert TicketPolicy.new(users(:employee), @own_ticket).rate?
  end

  test "cannot rate someone else's ticket, or one already rated" do
    @other_ticket.update!(status: :resolved)
    refute TicketPolicy.new(users(:employee), @other_ticket).rate?

    @own_ticket.update!(status: :resolved, satisfaction_rating: 5)
    refute TicketPolicy.new(users(:employee), @own_ticket).rate?
  end

  test "teammates on the same organization can view and update each other's tickets" do
    organization = Organization.create!(name: "Acme")
    owner = User.create!(email: "owner@example.com", password: "password123", role: :client, organization: organization, org_role: "owner")
    member = User.create!(email: "member@example.com", password: "password123", role: :client, organization: organization, org_role: "member")
    ticket = Ticket.create!(title: "Printer issue", user: owner)

    policy = TicketPolicy.new(member, ticket)
    assert policy.show?
    assert policy.update?
  end

  test "a teammate cannot rate a ticket they didn't personally file" do
    organization = Organization.create!(name: "Acme")
    owner = User.create!(email: "owner@example.com", password: "password123", role: :client, organization: organization, org_role: "owner")
    member = User.create!(email: "member@example.com", password: "password123", role: :client, organization: organization, org_role: "member")
    ticket = Ticket.create!(title: "Printer issue", user: owner, status: :resolved)

    refute TicketPolicy.new(member, ticket).rate?
    assert TicketPolicy.new(owner, ticket).rate?
  end

  test "clients on different organizations still can't see each other's tickets" do
    org_a = Organization.create!(name: "Acme")
    org_b = Organization.create!(name: "Globex")
    user_a = User.create!(email: "a@example.com", password: "password123", role: :client, organization: org_a, org_role: "owner")
    user_b = User.create!(email: "b@example.com", password: "password123", role: :client, organization: org_b, org_role: "owner")
    ticket = Ticket.create!(title: "Printer issue", user: user_a)

    refute TicketPolicy.new(user_b, ticket).show?

    scope = TicketPolicy::Scope.new(user_b, Ticket).resolve
    refute_includes scope, ticket
  end
end
