class Webhooks::StripeEventsController < ApplicationController
  protect_from_forgery with: :null_session
  skip_before_action :authenticate_user!

  def receive
    payload = request.body.read
    StripeInterface::EventReceiver.receive_event(JSON.parse(payload))
    render json: { status: 'success' }, status: :ok
  end
end
