class Webhooks::StripeEventsController < ApplicationController
  protect_from_forgery with: :null_session
  skip_before_action :authenticate_user!
  before_action :verify_stripe_signature!

  def receive
    StripeInterface::EventReceiver.receive_event(@event)
    render json: { status: 'success' }, status: :ok
  end

  private
  def verify_stripe_signature!
    sig_header = request.headers['HTTP_STRIPE_SIGNATURE']
    payload = request.body.read
    secret = ENV['STRIPE_WEBHOOK_SECRET']

    begin
      @event = Stripe::Webhook.construct_event(payload, sig_header, secret)
    rescue JSON::ParserError => e
      render json: { error: 'Invalid payload' }, status: :bad_request
      return false
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Stripe signature verification failed: #{e.message}"
      render json: { error: 'Invalid signature' }, status: :bad_request
      return false
    end

    true
  end
end
