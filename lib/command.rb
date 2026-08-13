module Command
  module Handler
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def handles(command_class, method_name)
        command_map[command_class] = method_name
      end

      def command_map
        @command_map ||= {}
      end
    end

    def call(command)
      method_name = self.class.command_map[command.class]
      raise ArgumentError, "No handler registered for #{command.class}" unless method_name

      send(method_name, command)
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def command_bus
      Rails.configuration.command_bus
    end
  end
end
