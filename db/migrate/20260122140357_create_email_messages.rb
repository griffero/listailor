class CreateEmailMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :email_messages do |t|
      t.references :application, null: false, foreign_key: true
      t.string :direction
      t.string :status
      t.string :from_address
      t.string :to_address
      t.string :subject
      t.text :body_html
      t.string :provider_message_id
      t.datetime :sent_at
      t.datetime :received_at

      t.timestamps
    end
  end
end
