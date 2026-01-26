class CreateSwapTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :swap_tickets do |t|
      t.references :device, null: false, foreign_key: true
      t.references :site, null: false, foreign_key: true
      t.date :scheduled_date
      t.string :status
      t.string :priority
      t.string :vendor_po
      t.text :notes

      t.timestamps
    end
  end
end
