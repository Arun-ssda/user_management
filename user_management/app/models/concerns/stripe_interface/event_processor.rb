module StripeInterface
  SUBSCRIPTION_CREATED_EVENT = 'customer.subscription.created'.freeze
  SUBSCRIPTION_DELETED_EVENT = 'customer.subscription.deleted'.freeze
  INVOICE_PAYMENT_SUCCEEDED_EVENT = 'invoice.payment_succeeded'.freeze
  ALLOWED_EVENT_TYPES = [SUBSCRIPTION_CREATED_EVENT, SUBSCRIPTION_DELETED_EVENT, INVOICE_PAYMENT_SUCCEEDED_EVENT].freeze
  ALLOWED_OBJECT_TYPES = %W(subscription invoice).freeze

  class EventProcessor

    def self.process(payload)
      event_type = payload['type'] || payload[:type]
      raise "Unsupported event type: #{event_type}" unless ALLOWED_EVENT_TYPES.include?(event_type)
      process_subscriptions(payload)
    end

    def self.process_subscriptions(payload)
      event = SubscriptionEventPayload.new(payload)
      StripeEventRecord.processed.exists?(event_id: event.id, event_type: event.type) && raise("Event already processed: #{event.id} of type #{event.type}")
      
      event_record = StripeEventRecord.log_event_received(event.payload)
      begin
        TransactionWrapper.wrap_in_transaction do
          event.validate!
          case event.type
          when SUBSCRIPTION_CREATED_EVENT
            handle_subscription_created(event)
          when SUBSCRIPTION_DELETED_EVENT
            handle_subscription_deleted(event)
          when INVOICE_PAYMENT_SUCCEEDED_EVENT
            handle_payment_succeeded(event)
          end
        end
        event_record.mark_as_processed!
      rescue StandardError => e
        event_record.error_message = e.message
        event_record.mark_as_errored!
      end
    end

    private

    def self.handle_subscription_created(event)
      event_entities_from(event, validate_existing_subscription: false) do |user, product, subscription|
        subscription ||= user.subscriptions.create!( stripe_subscription_id: event.subscription_id, product: product)
        validate_existing_subscription!(subscription, product, event)
        raise "Subscription already present and active for user #{user.customer_id} with subscription ID: #{event.subscription_id}" if subscription.paid?
        raise "Subscription already cancelled for user #{user.customer_id} with subscription ID: #{event.subscription_id}" if subscription.cancelled?
        subscription.initiate!
      end        
    end

    def self.handle_subscription_deleted(event)
      event_entities_from(event) do |user, product, subscription|
        raise "Subscription is already cancelled for user #{user.customer_id} with subscription ID: #{event.subscription_id}" if subscription.cancelled?
        subscription.cancel!
      end
    end

    def self.handle_payment_succeeded(event)
      event_entities_from(event) do |user, product, subscription|
        raise "Subscription is already paid for user #{user.customer_id} with subscription ID: #{event.subscription_id}" if subscription.paid?
        raise "Subscription is cancelled, cannot process payment for user #{user.customer_id} with subscription ID: #{event.subscription_id}" if subscription.cancelled?
        subscription.process_payment!
      end
    end

    def self.event_entities_from(event, validate_existing_subscription: true)      
      user = identify_user(event)
      product = identify_product(event)
      subscription = identify_subscription(user, event)
      validate_existing_subscription!(subscription, product) if validate_existing_subscription
      yield user, product, subscription
    end

    def self.identify_user(event)
      User.find_by(stripe_customer_id: event.customer_id) || raise("User not found for customer ID: #{event.customer_id}")
    end

    def self.identify_product(event)
      Product.find_by(stripe_product_id: event.product_id, stripe_price_id: event.price_id) || raise("Product not found for product ID: #{event.product_id} and price ID: #{event.price_id}")
    end

    def self.identify_subscription(user, event)
      user.subscriptions.find_by(stripe_subscription_id: event.subscription_id)
    end

    def self.validate_existing_subscription!(user, subscription, product, event)
      raise "Subscription not found for user #{user.customer_id} with subscription ID: #{event.subscription_id}" if subscription.nil?      
      raise "Subscription product mismatch: existing product #{subscription.product.id}, event product #{product.id}" if subscription.product != product
    end
  end
end