class Api::DronesController < ApplicationController
  skip_before_action :verify_authenticity_token
  def index
    render json: {
      active: 2,
      models: ["DJI Matrice 300", "Autel EVO II"],
      status: "LIVE"
    }
  end
end
