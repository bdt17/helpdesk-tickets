class CreateDevices < ActiveRecord::Migration[8.1]
  def change
    create_table :devices do |t|
      t.string :name
      t.string :model
      t.string :serial
      t.string :ip_address
      t.string :mac_address
      t.string :vendor
      t.references :site, null: false, foreign_key: true
      t.integer :status
      t.date :eol_date
      t.string :snmp_community

      t.timestamps
    end
  end
end
