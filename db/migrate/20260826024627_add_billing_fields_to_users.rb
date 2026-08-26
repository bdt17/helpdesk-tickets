class AddBillingFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :stripe_customer_id, :string
    add_index :users, :stripe_customer_id
    add_column :users, :stripe_subscription_id, :string
    add_index :users, :stripe_subscription_id
    add_column :users, :plan, :string
    add_column :users, :subscription_status, :string
  end
end
