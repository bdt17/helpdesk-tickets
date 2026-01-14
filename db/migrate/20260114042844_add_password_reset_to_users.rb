class AddPasswordResetToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :token, :string
    add_column :users, :sent_at, :datetime
  end
end
