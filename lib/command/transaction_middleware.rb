module Command
  class TransactionMiddleware
    def call(_command)
      ActiveRecord::Base.transaction { yield }
    end
  end
end