class AddCvInsightsToApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :applications, :has_startup_experience, :boolean
    add_column :applications, :has_year_tenure, :boolean
    add_column :applications, :has_personal_projects, :boolean
  end
end
