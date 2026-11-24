class AddTwoFactorToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :otp_secret, :string
    add_column :users, :otp_enabled_at, :datetime
    add_column :users, :otp_last_used_step, :integer
    add_column :users, :otp_backup_code_digests, :text
  end
end
