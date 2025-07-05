class CreateStripeEventRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :stripe_event_records do |t|
      t.string :event_id
      t.string :event_type
      t.json :payload
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
      t.string :stripe_product_id
      t.string :stripe_price_id
      t.string :status
      t.string :error_message, null: true
      t.timestamps
      t.index [:status, :event_type]
      t.index :event_id
    end
  end
end
