class DriversController < ApplicationController
  before_action :require_login
  before_action :set_driver, only: [:edit, :update, :destroy]

  def index
    @drivers = current_user.drivers
  end

  def new
    @driver = current_user.drivers.build
  end

  def create
    @driver = current_user.drivers.build(driver_params)

    if @driver.save
      redirect_to drivers_path, notice: "Driver added successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @driver.update(driver_params)
      redirect_to drivers_path, notice: "Driver updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @driver.destroy
    redirect_to drivers_path, notice: "Driver removed."
  end

  private

  def set_driver
    @driver = current_user.drivers.find(params[:id])
  end

  def driver_params
    params.require(:driver).permit(:name, :latitude, :longitude, :status)
  end
end
