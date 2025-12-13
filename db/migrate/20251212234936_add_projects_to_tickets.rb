class AddProjectsToTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :tickets, :project_id, :integer
  end
end
