class EnsureTicketsTableExists < ActiveRecord::Migration[8.1]
  def change
    unless table_exists?(:tickets)
      create_table :tickets do |t|
        t.string :title
        t.string :status, default: "Open"
        t.timestamps
      end
    end
  end
end

