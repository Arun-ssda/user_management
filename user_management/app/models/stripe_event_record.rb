#This model can be moved to nosql database like MongoDB or DynamoDB.
class StripeEventRecord < ApplicationRecord

  belongs_to :user, optional: true, foreign_key: 'stripe_customer_id', primary_key: 'stripe_customer_id'
  belongs_to :subscription, optional: true, foreign_key: 'stripe_subscription_id', primary_key: 'stripe_subscription_id'
  belongs_to :product, ->(obj) {where(stripe_price_id: obj.stripe_price_id)}, optional: true, foreign_key: 'stripe_product_id', primary_key: 'stripe_product_id'

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

  def self.log_event_received!(event_payload)
    StripeEventRecord.new(payload: event_payload).tap do |record|
      record.event_id = record.payload_object.id
      record.event_type = record.payload_object.type
      record.payload = event_payload.to_h
      record.stripe_customer_id = record.payload_object.customer_id
      record.stripe_subscription_id = record.payload_object.subscription_id
      record.stripe_product_id = record.payload_object.product_id
      record.stripe_price_id = record.payload_object.price_id
      record.status = 'received'
      record.save!
    end
  end

  def payload_object
    @payload_object ||= begin
      event_type = payload['type'] || payload[:type]
      payload_klass = StripeInterface::EventPayload.identify_payload_klass_for(event_type: event_type)
      obj = payload_klass.new(payload)
      obj
    end
  end

  def process!
    StripeInterface::EventProcessor.new(self).process_event_record!
    self.error_message.blank? ? mark_as_processed! : mark_as_errored!
  end
end
