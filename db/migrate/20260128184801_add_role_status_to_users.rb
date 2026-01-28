class AddRoleStatusToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :status, :integer, default: 1, null: false unless column_exists?(:users, :status)
  end
end
