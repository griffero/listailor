class CreateApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :applications do |t|
      t.references :job_posting, null: false, foreign_key: true
      t.references :candidate, null: false, foreign_key: true
      t.references :current_stage, foreign_key: { to_table: :pipeline_stages }
      t.string :source
      t.string :utm_source
      t.string :utm_medium
      t.string :utm_campaign
      t.string :utm_term
      t.string :utm_content

      t.timestamps
    end

    add_index :applications, [:job_posting_id, :candidate_id], unique: true
  end
end
