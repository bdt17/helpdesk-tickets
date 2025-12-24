class ShipmentsController < ApplicationController
  before_action :set_shipment, only: %i[show edit update destroy]

  def index
    @shipments = Shipment.all
  end

  private
    def set_shipment
      @shipment = Shipment.find(params[:id])
    end
end
