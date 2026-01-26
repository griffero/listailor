class SeedDefaultDepartments < ActiveRecord::Migration[7.2]
  def up
    departments = Setting.departments
    return if departments.any?

    Setting.departments = [
      "People", "Engineering", "Operations", "Admin",
      "Sales", "Marketing", "Other", "Strategy", "Finance"
    ]
  end

  def down
    # No-op: we don't want to remove departments on rollback
  end
end
