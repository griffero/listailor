class CreateJobQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :job_questions do |t|
      t.references :job_posting, null: false, foreign_key: true
      t.string :kind
      t.string :label
      t.boolean :required
      t.integer :position
      t.jsonb :options

      t.timestamps
    end
  end
end
