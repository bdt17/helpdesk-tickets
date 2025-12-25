class HomeController < ApplicationController
  def index
    render html: '<h1>✅ THOMAS HELPDESK LIVE</h1><p>Rails 8.1.1</p>'.html_safe
  end
end
