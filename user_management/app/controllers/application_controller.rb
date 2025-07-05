class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!
  around_action :wrap_transaction
  helper_method :current_user, :user_signed_in?

  def current_user
    return @current_user if defined?(@current_user)

    token = cookies.encrypted[:jwt]
    decoded = JsonWebToken.decode(token)
    @current_user = User.find_by(id: decoded["user_id"]) if decoded
  rescue JWT::DecodeError, JWT::ExpiredSignature
    cookies.delete(:jwt)
    nil
  end

  def user_signed_in?
    current_user.present?
  end

  def authenticate_user!
    redirect_to login_path, alert: "Please login" unless user_signed_in?
  end

  def wrap_transaction
    TransactionWrapper.wrap_in_transaction do
      yield
    end
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error e.message.inspect
    Rails.logger.error e.backtrace.inspect
    flash.now[:alert] = "An error occurred: #{e.message}"
    render :new, status: :internal_server_error
  end
end
