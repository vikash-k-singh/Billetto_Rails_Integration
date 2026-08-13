module Voting
  class VoteCountRebuilder
    def initialize(event_store: Rails.configuration.event_store)
      @event_store = event_store
    end

    def call(external_id: nil)
      clear_projection!(external_id)
      facts_for(external_id).each { |fact| VoteCountHandler.new.call(fact) }
    end

    private

    attr_reader :event_store

    def clear_projection!(external_id)
      if external_id
        event_ids = Event.where(external_id: external_id).select(:id)
        AppliedVoteFact.where(event_id: event_ids).delete_all
        VoteCount.where(event_id: event_ids).delete_all
      else
        AppliedVoteFact.delete_all
        VoteCount.delete_all
      end
    end

    def facts_for(external_id)
      if external_id
        event_store.read.stream("Voting$#{external_id}").to_a
      else
        event_store.read.of_type([ EventUpvoted, EventDownvoted ]).to_a
      end
    end
  end
end
