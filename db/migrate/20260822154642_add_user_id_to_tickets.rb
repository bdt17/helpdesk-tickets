class AddUserIdToTickets < ActiveRecord::Migration[8.1]
  def change
    add_reference :tickets, :user, null: true, foreign_key: true
  end
end
