class CreateSopTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :sop_tickets do |t|
      t.string :title
      t.string :status
      t.string :priority
      t.integer :account_id
      t.datetime :resolved_at

      t.timestamps
    end
  end
end
