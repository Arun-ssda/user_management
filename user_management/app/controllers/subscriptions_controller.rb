class SubscriptionsController < ApplicationController
  include SubscriptionsHelper

  def index
    @subscriptions = current_user.subscriptions.includes(:product)
    @available_subscriptions = available_unsubscribed_products()
  end

  def create
    @product = Product.find_by_id(product_params[:product_id])
    raise "Product not found" unless @product
    current_user.subscriptions.create!(product: @product)
    redirect_to subscriptions_path, notice: "Subscription created successfully"
  end

  private
  def product_params
    params.permit(:product_id)
  end
end
