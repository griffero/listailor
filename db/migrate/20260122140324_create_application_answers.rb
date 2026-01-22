class CreateApplicationAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :application_answers do |t|
      t.references :application, null: false, foreign_key: true
      t.references :job_question, null: false, foreign_key: true
      t.text :value

      t.timestamps
    end
  end
end
