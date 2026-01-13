class AddResolvedAtToSopTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :sop_tickets, :resolved_at, :datetime
  end
end
