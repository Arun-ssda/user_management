module StripeInterface
  SUBSCRIPTION_CREATED_EVENT = 'customer.subscription.created'.freeze
  SUBSCRIPTION_DELETED_EVENT = 'customer.subscription.deleted'.freeze
  INVOICE_PAYMENT_SUCCEEDED_EVENT = 'invoice.payment_succeeded'.freeze
  ALLOWED_EVENT_TYPES = [SUBSCRIPTION_CREATED_EVENT, SUBSCRIPTION_DELETED_EVENT, INVOICE_PAYMENT_SUCCEEDED_EVENT].freeze

  class EventReceiver
    def self.receive_event(payload)
      event_type = payload['type'] || payload[:type]
      raise "Unsupported event type: #{event_type}" unless ALLOWED_EVENT_TYPES.include?(event_type)
      event_record = StripeEventRecord.log_event_received!(payload)
      event_record.process!
    end
  end
end