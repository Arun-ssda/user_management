#This model can be moved to nosql database like MongoDB or DynamoDB.
class StripeEventRecord < ApplicationRecord

  scope :processed, -> { where(status: 'processed') }

  state_machine :status, initial: :received do
    state :received
    state :processed
    state :errored

    event :mark_as_processed do
      transition received: :processed
    end

    event :mark_as_errored do
      transition received: :errored
    end
  end

  def self.log_subscription_event_received(event_payload)
    StripeEventRecord.create(
      event_id: event_payload.id,
      event_type: event_payload.type,
      payload: event_payload.to_h,
      stripe_customer_id: event_payload.customer_id,
      stripe_subscription_id: event_payload.subscription_id,
      stripe_product_id: event_payload.product_id,
      stripe_price_id: event_payload.price_id,
      status: 'received'
    )
  end
end
