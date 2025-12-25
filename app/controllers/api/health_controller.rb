class Api::HealthController < ApplicationController
  def index
    render json: {status: 'ok', version: '1.0', env: Rails.env, timestamp: Time.current.utc.iso8601}
  end
end
