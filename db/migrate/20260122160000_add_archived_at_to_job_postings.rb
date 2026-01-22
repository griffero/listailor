class AddArchivedAtToJobPostings < ActiveRecord::Migration[8.0]
  def change
    add_column :job_postings, :archived_at, :datetime
    add_index :job_postings, :archived_at
  end
end
