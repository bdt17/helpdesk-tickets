class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets do |t|
      t.string :title
      t.text :description
      t.string :email
      t.string :status

      t.timestamps
    end
  end
end
