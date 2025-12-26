class Tech::DashboardController < ApplicationController
  skip_before_action :verify_authenticity_token  # FIX CSRF for demo
  
  def index
    @tickets = [
      {id: 1, title: "Pfizer site-42 HIGH", priority: "HIGH"},
      {id: 2, title: "FDA CRITICAL", priority: "URGENT"}
    ]
    @devices = [
      {id: 1, name: "iPhone 15", imei: "123456789"},
      {id: 2, name: "iPad Pro", imei: "987654321"}
    ]
    @sops = [
      {id: 1, title: "Device Swap SOP"},
      {id: 2, title: "FDA Compliance Check"}
    ]
  end
  
  def swap_device
    flash[:notice] = "✅ Device swapped to #{params[:device_id]}"
    redirect_to '/tech/dashboard'
  end
end
