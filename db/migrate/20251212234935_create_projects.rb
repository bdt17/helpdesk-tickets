class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :category
      t.text :equipment
      t.integer :priority
      t.string :status
      t.integer :tech_id
      t.integer :client_id

      t.timestamps
    end
  end
end
