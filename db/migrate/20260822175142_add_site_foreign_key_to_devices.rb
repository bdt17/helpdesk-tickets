class AddSiteForeignKeyToDevices < ActiveRecord::Migration[8.1]
  def change
    # create_devices (20260126223449) runs before create_sites (20260126223456),
    # so it can't declare this foreign key inline - sites doesn't exist yet at
    # that point when migrating a genuinely empty database (confirmed against
    # production Postgres, which enforces the FK target exists at creation
    # time; SQLite doesn't, which is why this never surfaced in dev/test).
    # Guarded because environments that loaded db/schema.rb directly already
    # have this constraint (schema.rb always creates tables before adding any
    # foreign keys, sidestepping the ordering problem entirely).
    add_foreign_key :devices, :sites unless foreign_key_exists?(:devices, :sites)
  end
end
