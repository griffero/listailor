class AddCoverLetterEvaluationToApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :applications, :cover_letter_evaluation, :jsonb
    add_column :applications, :cover_letter_decision, :string
  end
end
