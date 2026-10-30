xml.instruct!
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  [ root_path, services_path, *@services.map { |service| service_path(service.slug) } ].each do |path|
    xml.url { xml.loc public_url(path) }
  end
  xml.url { xml.loc public_url(articles_path) }
  @articles.each do |article|
    xml.url do
      xml.loc public_url(article_path(article))
      xml.lastmod article.updated_at.to_date.iso8601
    end
  end
end
