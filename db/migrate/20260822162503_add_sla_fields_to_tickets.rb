class AddSlaFieldsToTickets < ActiveRecord::Migration[8.1]
  SLA_WINDOWS = { "critical" => 4.hours, "high" => 24.hours, "medium" => 3.days, "low" => 7.days }.freeze

  class MigrationTicket < ActiveRecord::Base
    self.table_name = "tickets"
  end

  def up
    add_column :tickets, :due_at, :datetime
    add_column :tickets, :escalated_at, :datetime
    add_index :tickets, :due_at

    # Backfill existing rows using the same SLA windows the model uses
    # going forward, anchored to their original created_at. Done in Ruby
    # (not raw SQL) so it works the same on SQLite and Postgres.
    MigrationTicket.reset_column_information
    MigrationTicket.where(due_at: nil).find_each do |ticket|
      window = SLA_WINDOWS[ticket.priority] || SLA_WINDOWS["medium"]
      ticket.update_column(:due_at, ticket.created_at + window)
    end
  end

  def down
    remove_index :tickets, :due_at
    remove_column :tickets, :escalated_at, :datetime
    remove_column :tickets, :due_at, :datetime
  end
end
