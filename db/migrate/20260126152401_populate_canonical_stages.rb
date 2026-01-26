class PopulateCanonicalStages < ActiveRecord::Migration[7.2]
  def up
    PipelineStage.where(canonical_stage: nil).find_each do |stage|
      stage.update_column(:canonical_stage, stage.infer_canonical_stage)
    end
  end

  def down
    # No-op - we don't want to clear canonical stages on rollback
  end
end
