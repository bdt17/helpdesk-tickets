class AddRoleConstraintsToUsers < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE users SET role = 'employee' WHERE role IS NULL OR role = ''"
    change_column_default :users, :role, "employee"
    change_column_null :users, :role, false, "employee"
  end

  def down
    change_column_null :users, :role, true
    change_column_default :users, :role, nil
  end
end
