class Product < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :unit_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true

  has_many :subscriptions

  after_commit :create_product_in_stripe, on: :create

  private

  def create_product_in_stripe
    return if stripe_product_id.present? && stripe_price_id.present?

    StripeInterface::Adapter.create_product(name: name, unit_amount: unit_amount, currency: currency).tap do |product_data|
      if product_data
        self.update!(stripe_product_id: product_data[:product_id], stripe_price_id: product_data[:price_id])
      else
        raise "Failed to create product in Stripe"
      end
    end
  end
end
