class ShipmentsController < ApplicationController
  before_action :set_shipment, only: %i[ show edit update destroy ]

  # GET /shipments or /shipments.json
  def index
  @shipments = Shipment.where(status: [0,1]).order(created_at: :desc) # Active shipments
end

def temperature_alerts
  @alerts = Shipment.where("temperature_logs LIKE ?", "%CRITICAL%")
end


  # GET /shipments/1 or /shipments/1.json
  def show
  end

  # GET /shipments/new
  def new
    @shipment = Shipment.new
  end

  # GET /shipments/1/edit
  def edit
  end

  # POST /shipments or /shipments.json
  def create
    @shipment = Shipment.new(shipment_params)

    respond_to do |format|
      if @shipment.save
        format.html { redirect_to @shipment, notice: "Shipment was successfully created." }
        format.json { render :show, status: :created, location: @shipment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @shipment.errors, status: :unprocessable_entity }
      end
    end
  end

 class ShipmentsController < ApplicationController
  def index
    @shipments = Shipment.all
  end

  def show
    @shipment = Shipment.find(params[:id])
  end
end

