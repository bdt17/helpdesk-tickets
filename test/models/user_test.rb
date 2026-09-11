require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "role defaults to employee" do
    user = User.create!(email: "new-hire@thomasit.com", password: "password123", password_confirmation: "password123")
    assert user.employee?
  end

  test "role predicates match assigned role" do
    assert users(:employee).employee?
    assert users(:agent).agent?
    assert users(:admin).admin?
  end

  test "has lockable columns wired up" do
    assert_respond_to users(:employee), :failed_attempts
    assert_respond_to users(:employee), :locked_at
  end

  test "disabled users cannot authenticate" do
    user = users(:employee)
    user.update!(status: :disabled)
    refute user.active_for_authentication?
  end

  test "subscribed? and plan_definition delegate to the organization" do
    client = users(:client)
    assert_not client.subscribed?
    assert_nil client.plan_definition

    organization = Organization.create!(name: "Acme", plan: "business", subscription_status: "active")
    client.update!(organization: organization, org_role: "owner")

    assert client.subscribed?
    assert_equal "Business", client.plan_definition.name
  end

  test "org_role must be owner or member, or blank" do
    client = users(:client)
    client.organization = Organization.create!(name: "Acme")

    client.org_role = "superadmin"
    refute client.valid?

    client.org_role = "member"
    assert client.valid?
  end

  test "teammates returns other users on the same organization, excluding self" do
    organization = Organization.create!(name: "Acme")
    owner = User.create!(email: "owner@example.com", password: "password123", role: :client, organization: organization, org_role: "owner")
    member = User.create!(email: "member@example.com", password: "password123", role: :client, organization: organization, org_role: "member")

    assert_equal [ member ], owner.teammates.to_a
    assert_empty users(:employee).teammates
  end
end
