class AddTeamtailorIdToPipelineStages < ActiveRecord::Migration[8.0]
  def change
    add_column :pipeline_stages, :teamtailor_id, :string
    add_index :pipeline_stages, :teamtailor_id, unique: true
  end
end
