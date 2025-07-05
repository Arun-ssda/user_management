module StripeInterface
  class SubscriptionEventPayload
    include ActiveModel::Model
    include ActiveModel::Validations
    attr_accessor :payload, :id, :type, :stripe_object_type, :customer_id, :subscription_id, :product_id, :price_id

    validates :id, :type, :stripe_object_type, :customer_id, :subscription_id, :product_id, :price_id, presence: true
    validates :payload, presence: true
    validates :type, inclusion: { in: ALLOWED_EVENT_TYPES }
    validates :stripe_object_type, inclusion: { in: ALLOWED_OBJECT_TYPES }

    def initialize(payload)
      self.payload = payload.with_indifferent_access
      raise ArgumentError, 'Payload must be a Hash' unless self.payload.is_a?(Hash)
      self.id, self.type = self.payload.values_at('id', 'type')
      self.customer_id = self.payload.dig('data', 'object', 'customer')
      self.stripe_object_type = self.payload.dig('data', 'object', 'object')
      self.subscription_id = self.get_subscription_id()
      self.product_id, self.price_id = get_product_and_price_id.values_at(:product_id, :price_id)
    end

    private
    def get_subscription_id
      case stripe_object_type
      when 'subscription'
        self.payload.dig('data', 'object', 'id')
      when 'invoice'
        self.payload.dig('data', 'object', 'subscription')
      end
    end

    def get_product_and_price_id
      case stripe_object_type
      when 'subscription'
        {
          product_id: self.payload.dig('data', 'object', 'items', 'data', 0, 'price', 'product'),
          price_id: self.payload.dig('data', 'object', 'items', 'data', 0, 'price', 'id')
        }
      when 'invoice'
        {
          product_id: self.payload.dig('data', 'object', 'lines', 'data', 0, 'price', 'product'),
          price_id: self.payload.dig('data', 'object', 'lines', 'data', 0, 'price', 'id')
        }
      else
        {}
      end
    end
  end
end