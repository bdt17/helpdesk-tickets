class StatusController < ApplicationController
  def index
    render json: {status: 'ok', uptime: 99.9, version: '1.0'}
  end
end
