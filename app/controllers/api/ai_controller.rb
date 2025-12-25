class Api::AiController < ApplicationController
  def status
    render json: {status: "online", agents: 3, processing: "Pfizer site-42"}
  end
end
