Rails.configuration.event_store = RailsEventStore::Client.new

Rails.application.config.to_prepare do
  ApplicationSubscriptions.register(Rails.configuration.event_store)
end