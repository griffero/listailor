class CreateGlobalQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :global_questions do |t|
      t.string :kind
      t.string :label
      t.boolean :required, default: false
      t.integer :position
      t.jsonb :options

      t.timestamps
    end
  end
end
