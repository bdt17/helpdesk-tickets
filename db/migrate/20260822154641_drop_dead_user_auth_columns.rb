class DropDeadUserAuthColumns < ActiveRecord::Migration[8.1]
  def up
    remove_column :users, :password_digest, :string
    remove_column :users, :token, :string
    remove_column :users, :sent_at, :datetime
  end

  def down
    add_column :users, :password_digest, :string
    add_column :users, :token, :string
    add_column :users, :sent_at, :datetime
  end
end
