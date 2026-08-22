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
end
