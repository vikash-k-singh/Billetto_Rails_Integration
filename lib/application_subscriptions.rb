module ApplicationSubscriptions
  def self.handlers
    Voting.subscriptions
  end

  def self.register(event_store)
    handlers.each do |event_class, handler_classes|
      handler_classes.each do |handler_class|
        event_store.subscribe(
          ->(fact) { handler_class.new.call(fact) },
          to: [event_class]
        )
      end
    end
  end
end