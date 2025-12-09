class CreateKnowledgeBases < ActiveRecord::Migration[8.1]
  def change
    create_table :knowledge_bases do |t|
      t.string :title
      t.string :category
      t.text :steps
      t.text :commands
      t.text :client_instructions

      t.timestamps
    end
  end
end
