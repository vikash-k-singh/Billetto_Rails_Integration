module Command
  class CorrelationMiddleware
    KEY = :command_correlation_id

    def call(_command)
      previous = Thread.current[KEY]
      Thread.current[KEY] = SecureRandom.uuid
      yield
    ensure
      Thread.current[KEY] = previous
    end

    def self.current_id
      Thread.current[KEY]
    end
  end
end
