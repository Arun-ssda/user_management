class AddPasswordHashToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :password_hash, :string, null: false
  end
end
