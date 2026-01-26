class CreateSites < ActiveRecord::Migration[8.1]
  def change
    create_table :sites do |t|
      t.string :name
      t.string :address
      t.float :latitude
      t.float :longitude
      t.string :manager

      t.timestamps
    end
  end
end
