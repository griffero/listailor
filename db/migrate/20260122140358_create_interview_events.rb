class CreateInterviewEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :interview_events do |t|
      t.references :application, null: false, foreign_key: true
      t.datetime :scheduled_at
      t.integer :duration_minutes
      t.string :title
      t.string :meeting_url
      t.jsonb :participants

      t.timestamps
    end
  end
end
