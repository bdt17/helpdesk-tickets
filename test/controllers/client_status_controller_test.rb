require "test_helper"

class ClientStatusControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get client_status_show_url
    assert_response :success
  end
end
