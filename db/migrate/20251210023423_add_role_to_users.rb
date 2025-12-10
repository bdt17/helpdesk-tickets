class AddRoleToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :role, :string, default: 'client' unless column_exists? :users, :role
    add_index :users, :role unless index_exists? :users, :role
  end

  def down
    remove_column :users, :role
  end
end
