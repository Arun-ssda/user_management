class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name
      t.string :stripe_product_id
      t.string :stripe_price_id
      t.integer :unit_amount, null: false, default: 0
      t.string :currency, null: false, default: 'INR'
      t.timestamps
      t.index :name, unique: true
      t.index [:stripe_product_id, :stripe_price_id], unique: true
    end
  end
end
