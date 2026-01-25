class CreateTeamtailorSyncLocks < ActiveRecord::Migration[8.0]
  def change
    create_table :teamtailor_sync_locks do |t|
      t.string :key, null: false
      t.string :locked_by
      t.datetime :locked_at
      t.datetime :heartbeat_at
      t.timestamps
    end

    add_index :teamtailor_sync_locks, :key, unique: true
  end
end
