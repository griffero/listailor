class CreateJobPostings < ActiveRecord::Migration[8.0]
  def change
    create_table :job_postings do |t|
      t.string :title
      t.string :slug
      t.text :description
      t.string :department
      t.string :location
      t.datetime :published_at

      t.timestamps
    end
    add_index :job_postings, :slug, unique: true
  end
end
