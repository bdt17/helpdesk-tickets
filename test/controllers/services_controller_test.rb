require "test_helper"

class ServicesControllerTest < ActionDispatch::IntegrationTest
  test "services index lists every service, no login needed" do
    get services_url
    assert_response :success
    ServicePage::ALL.each do |service|
      assert_select "a[href=?]", service_path(service.slug)
    end
  end

  test "each service page renders with its own title and description" do
    ServicePage::ALL.each do |service|
      get service_url(service.slug)
      assert_response :success
      assert_select "title", text: /#{Regexp.escape(service.name)}/
      assert_select "meta[name=description][content=?]", service.summary
      assert_select "link[rel=canonical][href=?]", service_url(service.slug)
    end
  end

  test "an unknown service is a 404" do
    get service_url("not-a-service")
    assert_response :not_found
  end

  test "SERVICE_AREA is worked into titles and the homepage's structured data" do
    ENV["SERVICE_AREA"] = "Springfield, IL"
    get service_url("network-support")
    assert_select "title", text: /Network & Wi-Fi Support in Springfield, IL/

    get root_url
    assert_match '"areaServed":"Springfield, IL"', response.body
  ensure
    ENV.delete("SERVICE_AREA")
  end

  test "without SERVICE_AREA, no location is mentioned" do
    get root_url
    assert_no_match "areaServed", response.body
    assert_select "title", text: "Thomas Information Technology — Managed IT Help Desk"
  end

  test "the sitemap lists the homepage and every service page" do
    get sitemap_url
    assert_response :success
    assert_equal "application/xml", response.media_type
    assert_includes response.body, "<loc>#{root_url}</loc>"
    assert_includes response.body, "<loc>#{services_url}</loc>"
    ServicePage::ALL.each do |service|
      assert_includes response.body, "<loc>#{service_url(service.slug)}</loc>"
    end
  end

  test "every page's footer links to the service pages" do
    get root_url
    assert_select "footer a[href=?]", services_path
    assert_select "footer a[href=?]", service_path("managed-it-help-desk")
  end
end
