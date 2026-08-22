class ConvertUsersRoleToString < ActiveRecord::Migration[8.1]
  # AddRoleToUsers (20260128013707) added role as an integer. The migration
  # that originally converted it to a string (what AddRoleConstraintsToUsers,
  # 20260822154639, and every later role enum change already assume) was
  # never actually committed to this repo - it only ever existed as an
  # uncommitted local migration file on whoever's machine generated the
  # checked-in db/schema.rb, which has always shown role as a string. Local
  # dev/test never hit this gap because they load db/schema.rb directly
  # rather than migrating from an empty database; production does the
  # latter on a fresh db:prepare, which is what surfaced this.
  def up
    change_column_default :users, :role, from: 0, to: nil
    if postgres?
      execute "ALTER TABLE users ALTER COLUMN role TYPE character varying USING role::text"
    else
      change_column :users, :role, :string
    end
  end

  def down
    if postgres?
      execute "ALTER TABLE users ALTER COLUMN role TYPE integer USING role::integer"
    else
      change_column :users, :role, :integer
    end
    change_column_default :users, :role, from: nil, to: 0
  end

  private

  def postgres?
    connection.adapter_name.match?(/postg/i)
  end
end
