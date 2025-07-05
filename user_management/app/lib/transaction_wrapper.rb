module TransactionWrapper
  def self.wrap_in_transaction
    ActiveRecord::Base.transaction do
      yield
    end
  end
end