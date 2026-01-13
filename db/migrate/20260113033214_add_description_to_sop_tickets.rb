class AddDescriptionToSopTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :sop_tickets, :description, :text
  end
end
