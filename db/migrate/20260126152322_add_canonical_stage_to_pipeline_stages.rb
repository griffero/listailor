class AddCanonicalStageToPipelineStages < ActiveRecord::Migration[7.2]
  def change
    add_column :pipeline_stages, :canonical_stage, :string
    add_index :pipeline_stages, :canonical_stage
  end
end
