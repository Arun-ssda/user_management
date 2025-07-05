module StripeInterface
  class EventPayload
    include ActiveModel::Model
    include ActiveModel::Validations
    attr_accessor :payload, :id, :type, :customer_id, :subscription_id, :product_id, :price_id

    validates :id, :type, :customer_id, :subscription_id, presence: true
    validates :payload, presence: true
    validates :type, inclusion: { in: ALLOWED_EVENT_TYPES }

    def initialize(payload)
      self.payload = payload.with_indifferent_access
      raise ArgumentError, 'Payload must be a Hash' unless self.payload.is_a?(Hash)
      self.id, self.type = self.payload.values_at('id', 'type')
      self.customer_id = self.payload.dig('data', 'object', 'customer')
    end

    def self.identify_payload_klass_for(event_type: )
      return SubscriptionEventPayload if event_type.in?([SUBSCRIPTION_CREATED_EVENT, SUBSCRIPTION_DELETED_EVENT])
      return InvoiceEventPayload if event_type.in?([INVOICE_PAYMENT_SUCCEEDED_EVENT])
      raise "Invalid payload type"
    end

    def get_subscription_id
    end

    def get_product_and_price_id
    end
  end
end