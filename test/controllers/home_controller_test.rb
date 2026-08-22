require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get home_index_url
    assert_response :success
  end

  test "does not crash for a signed-in user with an unmapped role value" do
    # Regression test: a gap across the role migrations left every
    # pre-existing production user with role = "1" (a leftover from the
    # old integer-backed role column), which the enum silently reads back
    # as nil rather than raising - but the layout's navbar called
    # current_user.role.humanize unconditionally, and .humanize on nil
    # raised NoMethodError on every single page. Fixed by both a data
    # migration (FixLegacyIntegerRoleValues) and this defensive &.
    user = users(:employee)
    user.update_column(:role, "not-a-real-role")

    sign_in user
    get home_index_url

    assert_response :success
    assert_includes @response.body, "Employee"
  end
end
