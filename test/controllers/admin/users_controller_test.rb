require "test_helper"

module Admin
  class UsersControllerTest < ActionDispatch::IntegrationTest
    include ActionMailer::TestHelper

    test "only admins can see the users page" do
      sign_in users(:agent)
      get admin_users_url
      assert_redirected_to root_url

      sign_in users(:admin)
      get admin_users_url
      assert_response :success
      assert_select "td", text: users(:client).email
    end

    test "search and role filter narrow the list" do
      sign_in users(:admin)
      get admin_users_url(role: "client")
      assert_select "td", text: users(:client).email
      assert_select "td", text: users(:agent).email, count: 0

      get admin_users_url(q: users(:agent).email.split("@").first)
      assert_select "td", text: users(:agent).email
    end

    test "adding a staff member creates the account and emails a set-password link" do
      sign_in users(:admin)
      assert_difference "User.count", 1 do
        assert_emails 1 do
          post admin_users_url, params: { email: "New.Tech@Example.com", role: "agent" }
        end
      end
      assert_redirected_to admin_users_url
      assert User.find_by(email: "new.tech@example.com").agent?
    end

    test "staff can't be created as clients or duplicated" do
      sign_in users(:admin)
      assert_no_difference "User.count" do
        post admin_users_url, params: { email: "x@example.com", role: "client" }
        post admin_users_url, params: { email: users(:agent).email, role: "agent" }
      end
    end

    test "an admin can promote an agent and disable an account" do
      sign_in users(:admin)
      agent = users(:agent)
      patch admin_user_url(agent), params: { role: "admin" }
      assert agent.reload.admin?

      patch admin_user_url(users(:employee)), params: { status: "disabled" }
      assert users(:employee).reload.disabled?
    end

    test "a disabled user is signed out on their next request" do
      employee = users(:employee)
      sign_in employee
      get tickets_url
      assert_response :success

      employee.update!(status: :disabled)
      get tickets_url
      assert_redirected_to new_user_session_url
    end

    test "client roles can't be changed here" do
      sign_in users(:admin)
      patch admin_user_url(users(:client)), params: { role: "admin" }
      assert users(:client).reload.client?
      assert_equal "Client accounts' roles can't be changed here.", flash[:alert]
    end

    test "an admin can't remove their own admin access" do
      admin = users(:admin)
      sign_in admin
      patch admin_user_url(admin), params: { role: "agent" }
      assert admin.reload.admin?
      assert_equal "You can't remove your own admin access.", flash[:alert]

      patch admin_user_url(admin), params: { status: "disabled" }
      assert admin.reload.active?
    end

    test "an admin can demote another admin" do
      other = User.create!(email: "admin2@example.com", password: "password1234", role: :admin)
      sign_in users(:admin)
      patch admin_user_url(other), params: { role: "agent" }
      assert other.reload.agent?
    end

    test "admins see a Users link in the nav; agents don't" do
      sign_in users(:admin)
      get root_url
      assert_select "nav a[href=?]", admin_users_path

      sign_in users(:agent)
      get root_url
      assert_select "nav a[href=?]", admin_users_path, count: 0
    end
  end
end
