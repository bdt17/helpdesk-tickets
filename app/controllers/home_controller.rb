class HomeController < ApplicationController
  def index
    render html: "<h1>✅ THOMAS HELPDESK LIVE 8:50PM</h1><p>Rails 8.1.1 Render.com</p><p>Controllers clean. Zeitwerk happy.</p>".html_safe
  end
end
