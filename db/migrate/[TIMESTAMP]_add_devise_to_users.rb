class AddDeviseToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :encrypted_password, :string, null: false, default: ""
    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_sent_at, :datetime
    add_index :users, :reset_password_token, unique: true
    
    # Fix existing user
    reversible do |dir|
      dir.up do
        require 'securerandom'
        User.find_each do |user|
          user.update_column(:encrypted_password, Digest::SHA256.hexdigest("Th0masIT2025!SecurePass"))
        end
      end
    end
  end
end

