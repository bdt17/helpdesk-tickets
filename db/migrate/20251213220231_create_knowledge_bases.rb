class CreateKnowledgeBases < ActiveRecord::Migration[8.1]
  def change
    create_table :knowledge_bases do |t|
      t.string :title
      t.text :content
      t.string :category
      t.string :device_type

      t.timestamps
    end
  end
end
