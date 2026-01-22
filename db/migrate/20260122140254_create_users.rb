class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email
      t.string :magic_login_token_digest
      t.datetime :magic_login_sent_at
      t.datetime :last_signed_in_at

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
