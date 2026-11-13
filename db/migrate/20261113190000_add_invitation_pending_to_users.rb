class AddInvitationPendingToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :invitation_pending, :boolean, default: false, null: false
  end
end
