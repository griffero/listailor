class CreateApplicationStageTransitions < ActiveRecord::Migration[8.0]
  def change
    create_table :application_stage_transitions do |t|
      t.references :application, null: false, foreign_key: true
      t.references :from_stage, foreign_key: { to_table: :pipeline_stages }
      t.references :to_stage, null: false, foreign_key: { to_table: :pipeline_stages }
      t.datetime :transitioned_at, null: false

      t.timestamps
    end

    add_index :application_stage_transitions, [:application_id, :transitioned_at], name: "idx_app_stage_transitions_on_app_and_time"
  end
end
