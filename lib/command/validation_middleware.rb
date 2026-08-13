module Command
  class ValidationMiddleware
    def call(command)
      raise Invalid, command if command.respond_to?(:invalid?) && command.invalid?

      yield
    end
  end
end
