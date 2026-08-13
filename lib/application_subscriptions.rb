
module ApplicationSubscriptions
  def self.handlers
    # Voting.subscriptions
  end

  def self.register(event_store)
    # handlers.each do |event_class, handler_classes|
    #   handler_classes.each do |handler_class|
    #     # When a vote event is published, enqueue a Sidekiq job with the event ID.
    #     # The job fetches the full event from RES and calls handler_class#call.
    #     event_store.subscribe(
    #       ->(fact) { handler_class.perform_async(fact.event_id) },
    #       to: [event_class]
    #     )
    #   end
    # end
  end
end