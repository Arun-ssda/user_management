module SubscriptionsHelper
  def available_unsubscribed_products
    Product.where.not(id: current_user.subscriptions.active.pluck(:product_id))
  end
end
