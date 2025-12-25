module Api
  class ShipmentsController < ApplicationController
    def index
      render json: [
        {id: 1, site: "site-42", status: "in_transit", eta: "2025-12-26"},
        {id: 2, site: "site-17", status: "delivered"}
      ]
    end
  end
end
