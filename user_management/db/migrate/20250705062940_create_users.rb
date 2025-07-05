class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :stripe_customer_id
      t.timestamps
      t.index :email, unique: true
      t.index :stripe_customer_id, unique: true
    end
  end
end
