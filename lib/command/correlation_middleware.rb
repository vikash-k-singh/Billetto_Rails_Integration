module Command
  class CorrelationMiddleware
    KEY = :command_correlation_id

    def call(_command)
      Thread.current[KEY] ||= SecureRandom.uuid
      yield
    ensure
      Thread.current[KEY] = nil
    end

    def self.current_id
      Thread.current[KEY]
    end
  end
end