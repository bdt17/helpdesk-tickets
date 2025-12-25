module Api
  class HealthController < ApplicationController
    def index
      render json: {
        status: 'ok',
        version: '1.0.0',
        timestamp: Time.now.utc.iso8601,
        environment: Rails.env
      }
    end
  end
end
