class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string :title, null: false
      t.string :slug
      t.string :summary
      t.text :body, null: false
      t.string :category
      t.boolean :published, null: false, default: false

      t.timestamps
    end
    add_index :articles, :slug, unique: true
  end
end
