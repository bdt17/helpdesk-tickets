class AddPaymentFailureToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :payment_failed_at, :datetime
    add_column :organizations, :last_payment_failure_event_id, :string
  end
end
