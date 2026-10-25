xml.instruct!
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  [ root_path, services_path, *@services.map { |service| service_path(service.slug) } ].each do |path|
    xml.url { xml.loc public_url(path) }
  end
end
