# Solid Cache is already in the Gemfile but was never actually wired up
# (config.cache_store was unconfigured, so Rails silently fell back to its
# default file-store cache under tmp/cache/ - the same ephemeral-storage
# problem as Redis-backed Action Cable was before that got fixed to Solid
# Cable). This is what actually makes rate limiting (see
# RegistrationsController/TeamController) durable across restarts instead
# of resetting every deploy, and shareable if this app ever runs more
# than one process. Same single-database pattern as Solid Queue/Cable -
# no connects_to override, since config/cache.yml doesn't specify one.
class CreateSolidCacheEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :solid_cache_entries do |t|
      t.binary :key, limit: 1024, null: false
      t.binary :value, limit: 536870912, null: false
      t.datetime :created_at, null: false
      t.integer :key_hash, limit: 8, null: false
      t.integer :byte_size, limit: 4, null: false

      t.index :byte_size
      t.index [ :key_hash, :byte_size ]
      t.index :key_hash, unique: true
    end
  end
end
