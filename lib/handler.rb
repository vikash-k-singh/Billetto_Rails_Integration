module Handler
  # Subscription DSL used by ApplicationSubscriptions.
  # Projections run synchronously via ProjectionSubscriber, not Active Job.
  def self.async(queue: "default")
    class_methods = Module.new do
      define_method(:async_queue) { queue }

      def subscribes_to(*event_classes)
        @subscribed_to = event_classes
      end

      def subscriptions
        (@subscribed_to || []).each_with_object({}) do |event_class, hash|
          hash[event_class] = [ self ]
        end
      end
    end

    Module.new.tap do |mod|
      mod.define_singleton_method(:included) do |base|
        base.extend(class_methods)
      end

      mod.define_method(:call) do |_fact|
        raise NotImplementedError, "#{self.class} must implement #call"
      end

      mod.define_method(:event_store) { Rails.configuration.event_store }
      mod.define_method(:command_bus) { Rails.configuration.command_bus }
    end
  end
end
