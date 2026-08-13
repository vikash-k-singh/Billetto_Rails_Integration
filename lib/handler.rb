module Handler
  def self.async(queue: 'default')
    queue_name = queue

    class_methods = Module.new do
      def subscribes_to(*event_classes)
        @subscribed_to = event_classes
      end

      def subscriptions
        (@subscribed_to || []).each_with_object({}) do |event_class, hash|
          hash[event_class] = [self]
        end
      end
    end

    # define_singleton_method is required here because plain `def self.included`
    # inside Module.new creates a new scope and cannot close over `queue_name`.
    Module.new.tap do |mod|
      mod.define_singleton_method(:included) do |base|
        base.include(Sidekiq::Worker)
        base.sidekiq_options queue: queue_name
        base.extend(class_methods)
      end

      mod.define_method(:call) do |_fact|
        raise NotImplementedError, "#{self.class} must implement #call"
      end

      mod.define_method(:perform) do |event_id|
        fact = Rails.configuration.event_store.read.event(event_id)
        call(fact)
      end

      mod.define_method(:event_store) { Rails.configuration.event_store }
      mod.define_method(:command_bus) { Rails.configuration.command_bus }
    end
  end
end