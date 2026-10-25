class CreateLeads < ActiveRecord::Migration[8.1]
  def change
    create_table :leads do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :company
      t.string :phone
      t.text :message
      t.string :status, null: false, default: "new"

      t.timestamps
    end
    add_index :leads, :created_at
    add_index :leads, :status
  end
end
