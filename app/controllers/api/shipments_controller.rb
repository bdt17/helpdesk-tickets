module Api
  class ShipmentsController < ApplicationController
    def index
      render json: [{id:1,site:"site-42",status:"in_transit"}]
    end
  end
end
