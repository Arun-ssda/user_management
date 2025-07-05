module StripeInterface
  class EventProcessor
    attr_accessor :event_record

    def initialize(event_record)
      @event_record = event_record
      @event = event_record.payload_object
      @event_type = event_record.event_type
    end
  
    def process_event_record!
      raise "Unsupported event type: #{event_type}" unless ALLOWED_EVENT_TYPES.include?(@event_type)
      raise("Event already processed: #{@event.id} of type #{@event.type}") if StripeEventRecord.processed.exists?(event_id: @event.id, event_type: @event.type)
      begin
        TransactionWrapper.wrap_in_transaction do
          @event.validate!
          case @event.type
          when SUBSCRIPTION_CREATED_EVENT
            handle_subscription_created!
          when SUBSCRIPTION_DELETED_EVENT
            handle_subscription_deleted!
          when INVOICE_PAYMENT_SUCCEEDED_EVENT
            handle_payment_succeeded!
          end
        end
      rescue StandardError => e
        Rails.logger.error("Error processing Stripe event #{@event.id} of type #{@event.type}: #{e.message}\n#{e.backtrace.join("\n")}") 
        @event_record.error_message = e.message
      end
    end

    private

    def handle_subscription_created!
      user = @event_record.user
      product = @event_record.product
      subscription = @event_record.subscription
      subscription ||= user.subscriptions.create!( stripe_subscription_id: @event.subscription_id, product: product) if user && product && @event.subscription_id.present?

      validate_existing_subscription!
      raise "Subscription already present and active for user #{user.customer_id} with subscription ID: #{@event.subscription_id}" if subscription.paid?
      raise "Subscription already cancelled for user #{user.customer_id} with subscription ID: #{@event.subscription_id}" if subscription.cancelled?

      subscription.initiate!
    end

    def handle_subscription_deleted!
      user = @event_record.user
      subscription = @event_record.subscription

      validate_existing_subscription!
      raise "Subscription is already cancelled for user #{user.customer_id} with subscription ID: #{@event.subscription_id}" if subscription.cancelled?

      subscription.cancel!
    end

    def handle_payment_succeeded!
      user = @event_record.user
      subscription = @event_record.subscription

      raise "Subscription not found for user #{user.customer_id} with subscription ID: #{@event.subscription_id}" if subscription.nil?      
      raise "Subscription is already paid for user #{user.customer_id} with subscription ID: #{@event.subscription_id}" if subscription.paid?
      raise "Subscription is cancelled, cannot process payment for user #{user.customer_id} with subscription ID: #{@event.subscription_id}" if subscription.cancelled?

      subscription.process_payment!
    end

    def validate_existing_subscription!
      raise "User not found with customer ID: #{@event.customer_id}" if @event_record.user.nil?
      raise "Product not found with product ID: #{@event.product_id}" if @event_record.product.nil?
      raise "Subscription not found for user #{@event.customer_id} with subscription ID: #{@event.subscription_id}" if @event_record.reload_subscription.nil?
      raise "Subscription product mismatch: existing product #{@event_record.subscription&.product&.stripe_prdocut_id}, event product #{@event_record.stripe_prdocut_id}" if @event_record.subscription.product != @event_record.product
    end
  end
end