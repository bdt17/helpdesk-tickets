require "test_helper"

class Api::AiControllerTest < ActionDispatch::IntegrationTest
  test "should get status" do
    get api_ai_status_url
    assert_response :success
  end
end
