class CreatePipelineStages < ActiveRecord::Migration[8.0]
  def change
    create_table :pipeline_stages do |t|
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.string :kind, null: false, default: "active"

      t.timestamps
    end

    add_index :pipeline_stages, :position
    add_index :pipeline_stages, :kind
  end
end
