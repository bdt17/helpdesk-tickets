class CreateAiAgents < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_agents do |t|
      t.string :role
      t.integer :status
      t.text :content
      t.text :embedding

      t.timestamps
    end
  end
end
