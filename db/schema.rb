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

ActiveRecord::Schema[8.1].define(version: 2025_12_24_063919) do
  create_table "ai_agents", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.text "embedding"
    t.string "role"
    t.integer "status"
    t.datetime "updated_at", null: false
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

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "password_digest"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "drivers", "users"
end
