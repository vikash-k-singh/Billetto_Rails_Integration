module Command
  class InstrumentationMiddleware
    def call(command)
      name = "command.#{(command.class.name || command.class.to_s).underscore.tr('/', '.')}"
      ActiveSupport::Notifications.instrument(name, command: command) { yield }
    end
  end
end