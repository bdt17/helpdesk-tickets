json.extract! shipment, :id, :tracking_number, :status, :temperature_logs, :pickup_location, :delivery_location, :driver_id, :created_at, :updated_at
json.url shipment_url(shipment, format: :json)
