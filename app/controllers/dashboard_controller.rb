class DashboardController < ApplicationController
  before_action :require_login

  def index
    @drivers = current_user.drivers
  end

  # JSON endpoint for fetching driver locations (for map refresh)
  def drivers_json
    drivers = current_user.drivers.map do |driver|
      {
        id: driver.id,
        name: driver.name,
        latitude: driver.latitude,
        longitude: driver.longitude,
        status: driver.status,
        updated_at: driver.updated_at
      }
    end
    render json: drivers
  end
end
