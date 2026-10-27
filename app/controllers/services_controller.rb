# Public marketing pages (see ServicePage). No login - these are for
# prospects and search engines.
class ServicesController < ApplicationController
  def index
  end

  def show
    @service = ServicePage.find(params[:slug]) or raise ActionController::RoutingError, "Not Found"
  end
end
