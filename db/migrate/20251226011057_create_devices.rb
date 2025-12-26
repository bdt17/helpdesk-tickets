class CreateDevices < ActiveRecord::Migration[8.1]
  def change
    create_table :devices do |t|
      t.string :name
      t.string :imei
      t.string :status

      t.timestamps
    end
  end
end
