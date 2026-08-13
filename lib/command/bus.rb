module Command
  class Bus
    # Middleware executes outermost first: Correlation → Transaction → Instrumentation → handler
    MIDDLEWARE = [
      CorrelationMiddleware,
      TransactionMiddleware,
      InstrumentationMiddleware,
    ].freeze

    def initialize
      @registry = {}
    end

    def register(command_class, handler)
      @registry[command_class] = handler
    end

    def call(command)
      handler = @registry[command.class]
      raise ArgumentError, "No handler registered for #{command.class}" unless handler

      chain = MIDDLEWARE.reverse.reduce(-> { handler.call(command) }) do |inner, middleware_class|
        -> { middleware_class.new.call(command) { inner.call } }
      end

      chain.call
    end
  end
end