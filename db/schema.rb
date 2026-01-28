# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_28_013707) do
  create_table "devices", force: :cascade do |t|
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
    t.index ["site_id"], name: "index_devices_on_site_id"
  end

  create_table "drivers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "name"
    t.string "status"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_drivers_on_user_id"
  end

  create_table "shipments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "delivery_location"
    t.integer "driver_id"
    t.string "pickup_location"
    t.integer "status"
    t.text "temperature_logs"
    t.string "tracking_number"
    t.datetime "updated_at", null: false
  end

  create_table "sites", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.float "latitude"
    t.float "longitude"
    t.string "manager"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "sop_tickets", force: :cascade do |t|
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "priority"
    t.datetime "resolved_at"
    t.string "status"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "swap_tickets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "device_id", null: false
    t.text "notes"
    t.string "priority"
    t.date "scheduled_date"
    t.integer "site_id", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.string "vendor_po"
    t.index ["device_id"], name: "index_swap_tickets_on_device_id"
    t.index ["site_id"], name: "index_swap_tickets_on_site_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "encrypted_password"
    t.string "password_digest"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role"
    t.datetime "sent_at"
    t.string "token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["encrypted_password"], name: "index_users_on_encrypted_password"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token"
  end

  add_foreign_key "devices", "sites"
  add_foreign_key "drivers", "users"
  add_foreign_key "swap_tickets", "devices"
  add_foreign_key "swap_tickets", "sites"
end
