class DropSessionsTable < ActiveRecord::Migration[8.1]
  def up
    # The committed schema.rb never actually carried this table (it's absent
    # there despite the original CreateSessions migration existing), so guard
    # the drop in case it's missing in a given environment.
    drop_table :sessions, if_exists: true
  end

  def down
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.timestamps
    end
  end
end
