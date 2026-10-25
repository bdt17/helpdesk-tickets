class AddBillingIntervalToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :billing_interval, :string
  end
end
