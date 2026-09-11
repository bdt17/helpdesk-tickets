# Switches Action Cable's production adapter from Redis (never actually
# provisioned on Render — see config/cable.yml) to Solid Cable, which is
# already in the Gemfile and just needs this table. Runs in the same
# database as everything else, same pattern as Solid Queue's tables, so no
# extra service (and no extra memory pressure — see the OOM history in
# STATUS.md) is needed just to make ticket-escalation broadcasts actually
# reach a browser.
class CreateSolidCableMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :solid_cable_messages do |t|
      t.binary :channel, limit: 1024, null: false
      t.binary :payload, limit: 536870912, null: false
      t.datetime :created_at, null: false
      t.integer :channel_hash, limit: 8, null: false

      t.index :channel
      t.index :channel_hash
      t.index :created_at
    end
  end
end
