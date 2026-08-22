class DropSopTicketsTable < ActiveRecord::Migration[8.1]
  def up
    # SopTicket only ever held seeded pharma-demo rows, not real tickets -
    # confirmed fine to drop without a data migration into Ticket. Note
    # this is NOT reversible: `down` recreates the table structure so the
    # schema itself can roll back, but the rows are gone for good.
    drop_table :sop_tickets, if_exists: true
  end

  def down
    create_table :sop_tickets do |t|
      t.string :title
      t.string :status
      t.string :priority
      t.integer :account_id
      t.text :description
      t.datetime :resolved_at
      t.timestamps
    end
  end
end
