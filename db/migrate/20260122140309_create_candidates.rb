class CreateCandidates < ActiveRecord::Migration[8.0]
  def change
    create_table :candidates do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :linkedin_url

      t.timestamps
    end

    # Case-insensitive unique index on email for deduplication
    add_index :candidates, "lower(email)", unique: true, name: "index_candidates_on_lower_email"
  end
end
