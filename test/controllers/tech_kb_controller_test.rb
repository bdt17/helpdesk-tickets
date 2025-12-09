require "test_helper"

class TechKbControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get tech_kb_index_url
    assert_response :success
  end

  test "should get search" do
    get tech_kb_search_url
    assert_response :success
  end
end
