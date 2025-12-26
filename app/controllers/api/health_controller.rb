class Api::HealthController < ApplicationController
  skip_before_action :verify_authenticity_token
  def index
    render json: { status: "online", agents: 3, uptime: "99.9%" }
  end
end
