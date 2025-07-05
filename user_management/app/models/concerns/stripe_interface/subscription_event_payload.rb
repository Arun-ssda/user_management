module StripeInterface
  class SubscriptionEventPayload < EventPayload

    validates :subscription_id, :product_id, :price_id, presence: true

    def initialize(payload)
      super
      self.subscription_id = self.get_subscription_id()
      self.product_id, self.price_id = get_product_and_price_id.values_at(:product_id, :price_id)
    end

    def get_subscription_id
      self.payload.dig('data', 'object', 'id')
    end

    def get_product_and_price_id
      {
        product_id: self.payload.dig('data', 'object', 'items', 'data', 0, 'price', 'product'),
        price_id: self.payload.dig('data', 'object', 'items', 'data', 0, 'price', 'id')
      }
    end
  end
end