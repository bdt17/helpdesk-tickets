class AddRoleToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :integer, default: 0, null: false
    reversible do |dir|
      dir.up { execute("UPDATE users SET role = 1") }  # All users = agent
    end
  end
end
