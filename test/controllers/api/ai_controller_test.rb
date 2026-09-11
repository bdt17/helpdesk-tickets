require "test_helper"

class Api::AiControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get api_ai_status_url
    assert_response :redirect
  end

  test "requires staff role" do
    sign_in users(:client)
    get api_ai_status_url
    assert_redirected_to root_path
  end

  test "reports honest status for staff" do
    sign_in users(:agent)
    get api_ai_status_url
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal TicketCategorizer.configured?, json["configured"]
    assert_equal TicketCategorizer::MODEL, json["model"]
    assert_equal Ticket.count, json["tickets_total"]
    assert_equal Ticket.where(category_source: "ai").count, json["tickets_ai_categorized"]
  end
end
