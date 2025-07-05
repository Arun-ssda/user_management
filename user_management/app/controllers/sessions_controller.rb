class SessionsController < ApplicationController

  skip_before_action :authenticate_user!, only: [:new, :create]

  def new
    redirect_to root_path if user_signed_in?
  end

  def create
    user = User.find_by(email: user_params[:email])
    raise "User not found" unless user
    if user.password == user_params[:password]
      token = JsonWebToken.encode(user_id: user.id)

      cookies.encrypted[:jwt] = {
        value: token,
        httponly: true,
        expires: 1.hour.from_now
      }
      redirect_to root_path, notice: "Logged in successfully"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new
    end
  end

  def destroy
    cookies.delete(:jwt)
    @current_user = nil
    redirect_to login_path, notice: "Logged out"
  end

  private
  def user_params
    params.permit(:email, :password)
  end
end