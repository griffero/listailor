class MakePipelineStagesJobSpecific < ActiveRecord::Migration[8.0]
  def up
    # Add job_posting_id to pipeline_stages
    add_reference :pipeline_stages, :job_posting, foreign_key: true, index: true
    
    # Remove old unique index on teamtailor_id
    remove_index :pipeline_stages, :teamtailor_id if index_exists?(:pipeline_stages, :teamtailor_id)
    
    # Add new compound unique index
    add_index :pipeline_stages, [:job_posting_id, :teamtailor_id], 
              unique: true, 
              where: "teamtailor_id IS NOT NULL",
              name: "index_pipeline_stages_on_job_and_tt_id"
  end
  
  def down
    remove_index :pipeline_stages, name: "index_pipeline_stages_on_job_and_tt_id"
    add_index :pipeline_stages, :teamtailor_id, unique: true
    remove_reference :pipeline_stages, :job_posting
  end
end
