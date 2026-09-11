class AddSatisfactionToTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :tickets, :satisfaction_rating, :integer
    add_column :tickets, :satisfaction_comment, :text
  end
end
