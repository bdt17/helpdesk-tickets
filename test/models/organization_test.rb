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
end
