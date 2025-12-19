module Api
  class DriversController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :set_driver

    # POST /api/drivers/:id/location
    # Body: { "latitude": 40.7128, "longitude": -74.0060, "status": "active" }
    def update_location
      if @driver.update(location_params)
        render json: { success: true, driver: driver_json(@driver) }
      else
        render json: { success: false, errors: @driver.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def set_driver
      @driver = Driver.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { success: false, error: "Driver not found" }, status: :not_found
    end

    def location_params
      params.permit(:latitude, :longitude, :status)
    end

    def driver_json(driver)
      {
        id: driver.id,
        name: driver.name,
        latitude: driver.latitude,
        longitude: driver.longitude,
        status: driver.status,
        updated_at: driver.updated_at
      }
    end
  end
end
