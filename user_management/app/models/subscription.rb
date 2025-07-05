class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :product

  validates :user_id, presence: true
  validates :product_id, presence: true
  validate :user_must_have_stripe_customer_id, :product_must_have_stripe_ids

  after_commit :create_subscription_on_stripe, on: :create

  scope :active, -> { where(status: [:init, :unpaid, :paid]) }

  state_machine :status, initial: :init do
    state :unpaid
    state :paid
    state :cancelled
    
    event :initiate do
      transition [:init, :unpaid] => :unpaid
    end

    event :process_payment do
      transition [:init, :unpaid] => :paid
    end

    event :cancel do
      transition [:init, :unpaid, :paid] => :cancelled
    end
  end

  private

  def user_must_have_stripe_customer_id
    if user.stripe_customer_id.blank?
      errors.add(:user, "must have a Stripe customer ID")
    end
  end

  def product_must_have_stripe_ids
    if product.stripe_product_id.blank? || product.stripe_price_id.blank?
      errors.add(:product, "must have Stripe product and price IDs")
    end
  end

  def create_subscription_on_stripe
    return if stripe_subscription_id.present?

    StripeInterface::Adapter.create_subscription( user: user, product: product).tap do |stripe_subscription_id|
      if stripe_subscription_id
        self.update!(stripe_subscription_id: stripe_subscription_id, status: 'init')
      else
        raise "Failed to create subscription in Stripe"
      end
    end
  rescue StandardError => e
    Rails.logger.error("Stripe subscription creation failed: #{e.message}")
    raise e
  end
end
