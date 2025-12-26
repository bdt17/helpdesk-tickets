class CreateSops < ActiveRecord::Migration[8.1]
  def change
    create_table :sops do |t|
      t.string :title
      t.text :content

      t.timestamps
    end
  end
end
