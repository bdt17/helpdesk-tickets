require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "requires a name" do
    organization = Organization.new
    refute organization.valid?
    assert_includes organization.errors[:name], "can't be blank"
  end

  test "subscribed? mirrors the active/trialing statuses used elsewhere" do
    organization = Organization.new(name: "Acme")
    refute organization.subscribed?

    organization.subscription_status = "trialing"
    assert organization.subscribed?

    organization.subscription_status = "canceled"
    refute organization.subscribed?
  end

  test "owner and members split users by org_role" do
    organization = Organization.create!(name: "Acme")
    owner = User.create!(email: "owner@example.com", password: "password123", role: :client, organization: organization, org_role: "owner")
    member = User.create!(email: "member@example.com", password: "password123", role: :client, organization: organization, org_role: "member")

    assert_equal owner, organization.owner
    assert_equal [ member ], organization.members.to_a
  end

  test "an unsubscribed organization is capped at 1 seat" do
    organization = Organization.create!(name: "Acme")
    assert_equal 1, organization.max_seats
  end

  test "max_seats comes from the plan once subscribed" do
    organization = Organization.create!(name: "Acme", plan: "business", subscription_status: "active")
    assert_equal Plan.find("business").max_seats, organization.max_seats
  end

  test "seats_used counts every user on the organization, owner included" do
    organization = Organization.create!(name: "Acme", plan: "basic", subscription_status: "active")
    User.create!(email: "owner@example.com", password: "password123", role: :client, organization: organization, org_role: "owner")
    User.create!(email: "member@example.com", password: "password123", role: :client, organization: organization, org_role: "member")

    assert_equal 2, organization.seats_used
  end

  test "seats_available? is false once seats_used reaches max_seats" do
    organization = Organization.create!(name: "Acme", plan: "basic", subscription_status: "active") # max_seats: 3
    3.times { |n| User.create!(email: "user#{n}@example.com", password: "password123", role: :client, organization: organization, org_role: "member") }

    refute organization.seats_available?
  end
end
