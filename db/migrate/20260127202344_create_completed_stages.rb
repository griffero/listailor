class CreateCompletedStages < ActiveRecord::Migration[8.0]
  def change
    create_table :completed_stages do |t|
      t.references :application, null: false, foreign_key: true
      t.references :pipeline_stage, null: false, foreign_key: true
      t.datetime :completed_at, null: false, default: -> { "CURRENT_TIMESTAMP" }

      t.timestamps
    end

    add_index :completed_stages, [:application_id, :pipeline_stage_id], unique: true
  end
end
