class CreateTimeEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :time_entries do |t|
      t.references :ticket, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :minutes, null: false
      t.date :worked_on, null: false
      t.string :note

      t.timestamps
    end
    add_index :time_entries, :worked_on
  end
end
