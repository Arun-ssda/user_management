module StripeInterface
  class Adapter
    Stripe.api_key = ENV['STRIPE_API_KEY']
    Stripe.api_base = ENV['STRIPE_API_BASE']
    
    class << self
      def create_customer(name:, email:)
        customer = Stripe::Customer.create(
          name: name,
          email: email
        )
        customer.id
      rescue Stripe::StripeError => e
        Rails.logger.error "Stripe error while creating customer: #{e.message}"
        nil
      end

      def create_product(name:, unit_amount:, currency: 'INR')
        product = Stripe::Product.create( name: name)
        price = Stripe::Price.create( product: product.id, unit_amount: unit_amount, currency: currency)
        { product_id: product.id, price_id: price.id }
      rescue Stripe::StripeError => e
        Rails.logger.error "Stripe error while creating product: #{e.message}"
        nil
      end

      def create_subscription(user:, product:)
        return nil if user.stripe_customer_id.blank? || product.stripe_product_id.blank? || product.stripe_price_id.blank? 
        subscription = Stripe::Subscription.create( customer: user.stripe_customer_id, items: [{ price: product.stripe_price_id }])
        subscription.id
      rescue Stripe::StripeError => e
        Rails.logger.error "Stripe error while creating subscription: #{e.message}"
        nil
      end
    end
  end
end