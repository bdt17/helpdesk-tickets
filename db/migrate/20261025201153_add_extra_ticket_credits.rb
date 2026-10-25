class AddExtraTicketCredits < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :extra_ticket_credits, :integer, null: false, default: 0

    # One row per paid Stripe Checkout for extra tickets - the unique
    # session id is what stops a redelivered webhook crediting twice, and
    # it doubles as the record of add-on revenue.
    create_table :ticket_credit_purchases do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :stripe_checkout_session_id, null: false
      t.integer :quantity, null: false
      t.integer :amount_cents, null: false
      t.timestamps
    end
    add_index :ticket_credit_purchases, :stripe_checkout_session_id, unique: true
  end
end
