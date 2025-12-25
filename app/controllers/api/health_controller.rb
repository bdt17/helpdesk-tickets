class Api::HealthController < ApplicationController
  def index
    render json: { 
      status: 'ok', 
      uptime: Time.now.uptime.round(2), 
      version: '1.0.0',
      timestamp: Time.now.utc.iso8601
    }
  end
end
