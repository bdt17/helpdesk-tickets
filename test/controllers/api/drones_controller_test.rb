require "test_helper"

class Api::DronesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_drones_index_url
    assert_response :success
  end
end
