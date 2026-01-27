class AddRoleToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :role, :string, default: "viewer", null: false

    reversible do |dir|
      dir.up do
        # Make cristobal@fintoc.com an admin
        execute "UPDATE users SET role = 'admin' WHERE email = 'cristobal@fintoc.com'"
      end
    end
  end
end
