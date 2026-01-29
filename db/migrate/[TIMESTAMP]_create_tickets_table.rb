class CreateTicketsTable < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets do |t|
      t.string :title
      t.string :status, default: "Open"
      t.timestamps
    end
  end
end
