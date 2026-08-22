class AddFieldsToTickets < ActiveRecord::Migration[8.1]
  def up
    add_column :tickets, :description, :text
    add_column :tickets, :priority, :string, default: "medium", null: false
    add_column :tickets, :category, :string
    add_reference :tickets, :assignee, foreign_key: { to_table: :users }
    add_column :tickets, :resolved_at, :datetime

    execute "UPDATE tickets SET status = 'open' WHERE status IS NULL OR status = ''"
    change_column_default :tickets, :status, "open"
    change_column_null :tickets, :status, false, "open"
  end

  def down
    change_column_null :tickets, :status, true
    change_column_default :tickets, :status, nil

    remove_column :tickets, :resolved_at, :datetime
    remove_reference :tickets, :assignee, foreign_key: { to_table: :users }
    remove_column :tickets, :category, :string
    remove_column :tickets, :priority, :string
    remove_column :tickets, :description, :text
  end
end
