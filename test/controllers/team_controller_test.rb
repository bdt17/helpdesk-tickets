require "test_helper"

class TeamControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    Rails.cache.clear
    @organization = Organization.create!(name: "Acme", plan: "business", subscription_status: "active")
    @owner = users(:client)
    @owner.update!(organization: @organization, org_role: "owner")
  end

  test "requires authentication" do
    get team_url
    assert_redirected_to new_user_session_url
  end

  test "non-owners cannot manage the team" do
    sign_in users(:employee)
    get team_url
    assert_redirected_to billing_url
    assert_equal "Only the account owner can manage the team.", flash[:alert]
  end

  test "a team member (not owner) cannot manage the team" do
    member = User.create!(email: "member@example.com", password: "password123", role: :client, organization: @organization, org_role: "member")
    sign_in member
    get team_url
    assert_redirected_to billing_url
  end

  test "owner sees the team page" do
    sign_in @owner
    get team_url
    assert_response :success
    assert_includes @response.body, @owner.email
  end

  test "owner can invite a new teammate by email" do
    sign_in @owner

    assert_difference "User.count", 1 do
      assert_emails 1 do
        post team_invite_url, params: { email: "new-teammate@example.com" }
      end
    end

    invited = User.find_by(email: "new-teammate@example.com")
    assert_equal @organization, invited.organization
    assert_equal "member", invited.org_role
    assert invited.client?
    assert_redirected_to team_url
  end

  test "cannot invite an email that already has an account" do
    sign_in @owner

    assert_no_difference "User.count" do
      post team_invite_url, params: { email: users(:employee).email }
    end

    assert_equal "That email already has an account.", flash[:alert]
  end

  test "owner can remove a teammate" do
    member = User.create!(email: "member@example.com", password: "password123", role: :client, organization: @organization, org_role: "member")
    sign_in @owner

    delete team_member_url(member)

    member.reload
    assert_nil member.organization_id
    assert_nil member.org_role
  end

  test "owner cannot remove themselves" do
    sign_in @owner
    delete team_member_url(@owner)

    assert_equal @organization, @owner.reload.organization
    assert_equal "You can't remove yourself from the team.", flash[:alert]
  end

  test "invites are rate-limited per owner after 10 within an hour" do
    sign_in @owner

    10.times { |n| post team_invite_url, params: { email: "rl-#{n}@example.com" } }

    assert_no_difference "User.count" do
      post team_invite_url, params: { email: "rl-blocked@example.com" }
    end

    assert_redirected_to team_url
    assert_equal "Too many invites sent. Please try again in a bit.", flash[:alert]
  end

  test "the invite rate limit is per owner, not global" do
    other_organization = Organization.create!(name: "Globex", plan: "business", subscription_status: "active")
    other_owner = User.create!(email: "other-owner@example.com", password: "password123", role: :client, organization: other_organization, org_role: "owner")

    sign_in @owner
    10.times { |n| post team_invite_url, params: { email: "rl-#{n}@example.com" } }

    sign_out @owner
    sign_in other_owner
    assert_difference "User.count", 1 do
      post team_invite_url, params: { email: "not-blocked@example.com" }
    end
  end

  test "removing a teammate isn't affected by the invite rate limit" do
    member = User.create!(email: "member@example.com", password: "password123", role: :client, organization: @organization, org_role: "member")
    sign_in @owner

    10.times { |n| post team_invite_url, params: { email: "rl-#{n}@example.com" } }

    delete team_member_url(member)
    assert_nil member.reload.organization_id
  end

  test "cannot invite past the plan's seat limit" do
    organization = Organization.create!(name: "Small Co", plan: "basic", subscription_status: "active") # max_seats: 3
    owner = User.create!(email: "small-owner@example.com", password: "password123", role: :client, organization: organization, org_role: "owner")
    2.times { |n| User.create!(email: "seat#{n}@example.com", password: "password123", role: :client, organization: organization, org_role: "member") }
    # 3 seats used (owner + 2 members) out of 3 allowed on Basic

    sign_in owner
    assert_no_difference "User.count" do
      post team_invite_url, params: { email: "one-too-many@example.com" }
    end

    assert_redirected_to team_url
    follow_redirect!
    assert_includes @response.body, "Basic plan allows up to 3 seats"
  end

  test "removing a teammate frees a seat back up" do
    organization = Organization.create!(name: "Small Co", plan: "basic", subscription_status: "active")
    owner = User.create!(email: "small-owner@example.com", password: "password123", role: :client, organization: organization, org_role: "owner")
    member1 = User.create!(email: "seat0@example.com", password: "password123", role: :client, organization: organization, org_role: "member")
    User.create!(email: "seat1@example.com", password: "password123", role: :client, organization: organization, org_role: "member")
    # full at 3/3

    sign_in owner
    delete team_member_url(member1)

    assert_difference "User.count", 1 do
      post team_invite_url, params: { email: "replacement@example.com" }
    end
  end

  test "the team page shows seat usage and hides the invite form once full" do
    organization = Organization.create!(name: "Small Co", plan: "basic", subscription_status: "active")
    owner = User.create!(email: "small-owner@example.com", password: "password123", role: :client, organization: organization, org_role: "owner")
    2.times { |n| User.create!(email: "seat#{n}@example.com", password: "password123", role: :client, organization: organization, org_role: "member") }

    sign_in owner
    get team_url

    assert_includes @response.body, "3 of 3 seats used"
    assert_not_includes @response.body, "teammate@company.com" # the invite form's placeholder
  end
end
