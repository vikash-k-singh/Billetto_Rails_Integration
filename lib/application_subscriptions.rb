module ApplicationSubscriptions
  def self.handlers
    Voting.subscriptions
  end

  def self.register(event_store)
    return if event_store.instance_variable_get(:@application_subscriptions_registered)

    handlers.each do |event_class, handler_classes|
      handler_classes.uniq.each do |handler_class|
        event_store.subscribe(ProjectionSubscriber.new(handler_class), to: [ event_class ])
      end
    end

    event_store.instance_variable_set(:@application_subscriptions_registered, true)
  end
end
