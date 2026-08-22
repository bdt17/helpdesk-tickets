class EnsureTicketsTableExists < ActiveRecord::Migration[8.1]
  # This migration's change method was committed empty - a no-op. The actual
  # create_table logic only ever existed in a duplicate placeholder file
  # ([NEW_TIMESTAMP]_ensure_tickets_table_exists.rb, deleted in Phase 1 as
  # dead cruft with an unparseable version) that was never itself a real,
  # applied migration. Nothing in the committed migration history has ever
  # actually created the tickets table; local dev/test never noticed
  # because they load db/schema.rb directly rather than migrating from an
  # empty database. if_not_exists guards against whatever partial state
  # this database may have accumulated across several failed deploy
  # attempts already.
  def change
    create_table :tickets, if_not_exists: true do |t|
      t.string :title
      t.string :status, default: "Open"
      t.timestamps
    end
  end
end
