# Phase 12: multi-seat billing. Moves the subscription (stripe_customer_id,
# stripe_subscription_id, subscription_status, plan) off User and onto a
# new Organization that can hold multiple client users, instead of one
# subscription per user. Existing subscribed clients (real production
# data - see STATUS.md's test client) keep their plan: each one gets their
# own one-person Organization carrying over their exact billing state,
# with org_role "owner" so nothing about their billing access changes.
#
# The data copy is plain ActiveRecord (find_each/create!/update!), not raw
# SQL, since this app runs SQLite in dev/test and PostgreSQL in
# production and a hand-written UPDATE...FROM wouldn't be portable
# between them.
class CreateOrganizationsAndMoveBilling < ActiveRecord::Migration[8.1]
  def up
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
      t.string :subscription_status
      t.string :plan
      t.timestamps
    end
    add_index :organizations, :stripe_customer_id, unique: true
    add_index :organizations, :stripe_subscription_id, unique: true

    add_reference :users, :organization, foreign_key: true
    add_column :users, :org_role, :string

    user_klass.reset_column_information
    user_klass.where.not(stripe_customer_id: nil).find_each do |user|
      org = org_klass.create!(
        name: user.email,
        stripe_customer_id: user.stripe_customer_id,
        stripe_subscription_id: user.stripe_subscription_id,
        subscription_status: user.subscription_status,
        plan: user.plan
      )
      user.update_columns(organization_id: org.id, org_role: "owner")
    end

    remove_column :users, :stripe_customer_id
    remove_column :users, :stripe_subscription_id
    remove_column :users, :subscription_status
    remove_column :users, :plan
  end

  def down
    add_column :users, :stripe_customer_id, :string
    add_column :users, :stripe_subscription_id, :string
    add_column :users, :subscription_status, :string
    add_column :users, :plan, :string
    add_index :users, :stripe_customer_id
    add_index :users, :stripe_subscription_id

    user_klass.reset_column_information
    user_klass.where.not(organization_id: nil).find_each do |user|
      org = org_klass.find_by(id: user.organization_id)
      next unless org

      user.update_columns(
        stripe_customer_id: org.stripe_customer_id,
        stripe_subscription_id: org.stripe_subscription_id,
        subscription_status: org.subscription_status,
        plan: org.plan
      )
    end

    remove_reference :users, :organization, foreign_key: true
    remove_column :users, :org_role
    drop_table :organizations
  end

  private

  def user_klass
    @user_klass ||= Class.new(ActiveRecord::Base) { self.table_name = "users" }
  end

  def org_klass
    @org_klass ||= Class.new(ActiveRecord::Base) { self.table_name = "organizations" }
  end
end
