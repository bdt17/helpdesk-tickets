require "application_system_test_case"

class ProductionDashboardsTest < ApplicationSystemTestCase
  test "pharma dashboard production live" do
    visit "https://thomasinformationtechnology.com/"
    assert_selector "title", text: /Thomas IT/
    assert_text "Thomas IT Analytics"
    assert_text "dashboard"
  end
  
  test "network dashboard production live" do
    visit "https://thomasinformationtechnology.com/network-dashboard"
    assert_selector "body"
    assert_text "dashboard", maximum: 10
  end
end
