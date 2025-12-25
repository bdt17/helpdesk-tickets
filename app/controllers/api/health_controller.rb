module Api
  class HealthController < ApplicationController
    def index
      render json: {
        status: 'ok',
        version: '1.0',
        env: Rails.env,
        timestamp: Time.now.utc.iso8601
      }
    end
  end
end
