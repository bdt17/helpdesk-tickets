module Api
  class HealthController < ApplicationController
    def index
      render json: {status: 'ok', version: '1.0', env: Rails.env}
    end
  end
end
