class UpdateJobQuestionTeamtailorIndex < ActiveRecord::Migration[8.0]
  def change
    remove_index :job_questions, :teamtailor_id if index_exists?(:job_questions, :teamtailor_id)
    add_index :job_questions, [:job_posting_id, :teamtailor_id], unique: true
  end
end
