# The Shipment/Driver/Device/Site/SwapTicket models, controllers, helpers,
# and views from a prior logistics-app iteration sharing this codebase were
# removed as dead code (no routes, no references anywhere in app/) in a
# previous commit. This finishes that cleanup by dropping the now-unused
# tables themselves. Confirmed empty in production before writing this
# (devices/drivers/shipments/sites/swap_tickets: 0 rows each).
class DropDeadLogisticsTables < ActiveRecord::Migration[8.1]
  def up
    # Drop in dependency order: swap_tickets and devices both reference
    # sites; swap_tickets also references devices.
    drop_table :swap_tickets
    drop_table :devices
    drop_table :sites
    drop_table :drivers
    drop_table :shipments
  end

  def down
    create_table :sites do |t|
      t.string "address"
      t.datetime "created_at", null: false
      t.float "latitude"
      t.float "longitude"
      t.string "manager"
      t.string "name"
      t.datetime "updated_at", null: false
    end

    create_table :devices do |t|
      t.datetime "created_at", null: false
      t.date "eol_date"
      t.string "ip_address"
      t.string "mac_address"
      t.string "model"
      t.string "name"
      t.string "serial"
      t.integer "site_id", null: false
      t.string "snmp_community"
      t.integer "status"
      t.datetime "updated_at", null: false
      t.string "vendor"
      t.index [ "site_id" ], name: "index_devices_on_site_id"
    end
    add_foreign_key :devices, :sites

    create_table :swap_tickets do |t|
      t.datetime "created_at", null: false
      t.integer "device_id", null: false
      t.text "notes"
      t.string "priority"
      t.date "scheduled_date"
      t.integer "site_id", null: false
      t.string "status"
      t.datetime "updated_at", null: false
      t.string "vendor_po"
      t.index [ "device_id" ], name: "index_swap_tickets_on_device_id"
      t.index [ "site_id" ], name: "index_swap_tickets_on_site_id"
    end
    add_foreign_key :swap_tickets, :devices
    add_foreign_key :swap_tickets, :sites

    create_table :drivers do |t|
      t.datetime "created_at", null: false
      t.decimal "latitude", precision: 10, scale: 6
      t.decimal "longitude", precision: 10, scale: 6
      t.string "name"
      t.string "status"
      t.datetime "updated_at", null: false
      t.integer "user_id", null: false
      t.index [ "user_id" ], name: "index_drivers_on_user_id"
    end
    add_foreign_key :drivers, :users

    create_table :shipments do |t|
      t.datetime "created_at", null: false
      t.string "delivery_location"
      t.integer "driver_id"
      t.string "pickup_location"
      t.integer "status"
      t.text "temperature_logs"
      t.string "tracking_number"
      t.datetime "updated_at", null: false
    end
  end
end
