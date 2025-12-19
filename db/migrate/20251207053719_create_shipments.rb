class CreateShipments < ActiveRecord::Migration[8.1]
  def change
    create_table :shipments do |t|
      t.string :tracking_number
      t.integer :status
      t.text :temperature_logs
      t.string :pickup_location
      t.string :delivery_location
      t.integer :driver_id

      t.timestamps
    end
  end
end
