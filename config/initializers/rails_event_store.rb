Rails.application.config.to_prepare do
  Rails.configuration.event_store = RailsEventStore::Client.new(
    message_broker: RubyEventStore::Broker.new(
      subscriptions: RubyEventStore::Subscriptions.new,
      dispatcher: RubyEventStore::Dispatcher.new
    )
  )
  ApplicationSubscriptions.register(Rails.configuration.event_store)
end
