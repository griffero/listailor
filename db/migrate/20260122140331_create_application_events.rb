class CreateApplicationEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :application_events do |t|
      t.references :application, null: false, foreign_key: true
      t.references :created_by_user, foreign_key: { to_table: :users }
      t.string :event_type, null: false
      t.text :message
      t.jsonb :payload, default: {}
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :application_events, [:application_id, :occurred_at]
  end
end
