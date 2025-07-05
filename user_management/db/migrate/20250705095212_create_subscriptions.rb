class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.integer :user_id
      t.integer :product_id
      t.string :stripe_subscription_id
      t.string :status
      t.timestamps
      t.index [:user_id, :status]
      t.index [:product_id, :status]
    end
  end
end
