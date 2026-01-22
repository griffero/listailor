class AddTeamtailorFields < ActiveRecord::Migration[8.0]
  def change
    add_column :job_postings, :teamtailor_id, :string
    add_column :candidates, :teamtailor_id, :string
    add_column :applications, :teamtailor_id, :string
    add_column :job_questions, :teamtailor_id, :string
    add_column :email_messages, :teamtailor_id, :string

    add_index :job_postings, :teamtailor_id, unique: true
    add_index :candidates, :teamtailor_id, unique: true
    add_index :applications, :teamtailor_id, unique: true
    add_index :job_questions, :teamtailor_id, unique: true
    add_index :email_messages, :teamtailor_id, unique: true

    create_table :teamtailor_sync_states do |t|
      t.string :resource, null: false
      t.string :cursor
      t.datetime :last_synced_at
      t.timestamps
    end

    add_index :teamtailor_sync_states, :resource, unique: true
  end
end
