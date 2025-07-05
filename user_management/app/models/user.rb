class User < ApplicationRecord
  include BCrypt
  attr_accessor :password
  validates :name, :email, :password, presence: true
  validates :email, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  before_save :encrypt_password
  after_commit :create_customer_in_stripe, on: :create

  has_many :subscriptions
  
  def password
    @password ||= BCrypt::Password.new(password_hash)
  end

  private
  def create_customer_in_stripe
    return if stripe_customer_id.present?
    StripeInterface::Adapter.create_customer(name: name, email: email).tap do |customer_id|
      if customer_id
        self.update!(stripe_customer_id: customer_id)
      else
        raise "Failed to create customer in Stripe"
      end
    end
  end

  def encrypt_password
    self.password_hash = BCrypt::Password.create(password)
  end
end
