class AddTeamtailorSyncChecksToApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :applications, :teamtailor_state_synced_at, :datetime
    add_column :applications, :teamtailor_full_sync_at, :datetime

    add_index :applications, :teamtailor_state_synced_at
    add_index :applications, :teamtailor_full_sync_at
  end
end
