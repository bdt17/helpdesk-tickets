class HomeController < ApplicationController
  def index
    render html: "<h1>✅ THOMAS HELPDESK LIVE 9:19PM</h1><p>Rails 8.1.1 Render.com</p>".html_safe
  end
end
