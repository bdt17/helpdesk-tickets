class AddCancellationFieldsToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :cancel_at, :datetime
    add_column :organizations, :cancellation_reason, :string
    add_column :organizations, :cancellation_comment, :text
    add_column :organizations, :retention_offer_used_at, :datetime
  end
end
