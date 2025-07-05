module StripeInterface
  class InvoiceEventPayload < EventPayload

    validates :subscription_id, presence: true

    def initialize(payload)
      super
      self.subscription_id = self.get_subscription_id()
    end

    def get_subscription_id
      self.payload.dig('data', 'object', 'subscription')
    end

    def get_product_and_price_id
      {
        product_id: self.payload.dig('data', 'object', 'lines', 'data', 0, 'price', 'product'),
        price_id: self.payload.dig('data', 'object', 'lines', 'data', 0, 'price', 'id')
      }
    end
  end
end