class AddEducationFieldsToApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :applications, :education, :jsonb
    add_column :applications, :processing_completed_at, :datetime
    add_index :applications, :processing_completed_at
  end
end
