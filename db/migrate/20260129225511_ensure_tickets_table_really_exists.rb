class EnsureTicketsTableReallyExists < ActiveRecord::Migration[8.1]
  # EnsureTicketsTableExists (20260129225510) was committed as a no-op and
  # is already recorded as applied on production (it ran, successfully,
  # doing nothing, during an earlier partial deploy attempt that failed
  # later). Fixing that file's content alone would not help this database -
  # Rails never re-runs a version already marked up. This migration exists
  # specifically to create the table on databases already past that point.
  # if_not_exists makes it a harmless no-op anywhere the table already
  # exists (including via 20260129225510 now that it's fixed, for any
  # database that migrates through both from scratch).
  def change
    create_table :tickets, if_not_exists: true do |t|
      t.string :title
      t.string :status, default: "Open"
      t.timestamps
    end
  end
end
