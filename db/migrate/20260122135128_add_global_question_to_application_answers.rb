class AddGlobalQuestionToApplicationAnswers < ActiveRecord::Migration[8.0]
  def change
    add_reference :application_answers, :global_question, foreign_key: true
    change_column_null :application_answers, :job_question_id, true
  end
end
