module Api
  class TicketsController < ApplicationController
    def index
      render json: [
        {id: 1, title: "Pfizer shipment delay - site-42", status: "open", priority: "high"},
        {id: 2, title: "FDA compliance alert", status: "in_progress", priority: "critical"},
        {id: 3, title: "Drone dispatch confirmed", status: "resolved"}
      ]
    end
  end
end
