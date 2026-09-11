require "test_helper"

class TeamControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
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
end
