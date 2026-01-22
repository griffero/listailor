class RenameMagicLoginTokenDigestToMagicLoginToken < ActiveRecord::Migration[8.0]
  def change
    rename_column :users, :magic_login_token_digest, :magic_login_token
  end
end
