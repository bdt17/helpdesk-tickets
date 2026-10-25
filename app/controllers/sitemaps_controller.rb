# /sitemap.xml - the public pages we want search engines to index
# (referenced from public/robots.txt).
class SitemapsController < ApplicationController
  def show
    @services = ServicePage::ALL
    respond_to { |format| format.xml }
  end
end
