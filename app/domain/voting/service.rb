module Voting
  class Service
    include Command::Handler

    handles Voting::UpvoteEvent,   :upvote
    handles Voting::DownvoteEvent, :downvote

    private

    def upvote(command)
      cast_vote(command, EventUpvoted)
    end

    def downvote(command)
      cast_vote(command, EventDownvoted)
    end

    def cast_vote(command, fact_class)
      Event.find_by!(external_id: command.event_id)
      return if existing_vote(command.event_id, command.user_id)

      fact = fact_class.strict(data: { event_id: command.event_id, user_id: command.user_id })
      apply_command_metadata(fact)
      publish_to_streams(fact)
    rescue RubyEventStore::WrongExpectedEventVersion
      # Concurrent duplicate on Vote$event$user with expected_version: :none
    end

    def existing_vote(event_id, user_id)
      event_store
        .read
        .stream(vote_stream_name(event_id, user_id))
        .limit(1)
        .to_a
        .first
    end

    def apply_command_metadata(fact)
      command_id = Command::CorrelationMiddleware.current_id
      return if command_id.blank?

      fact.metadata[:correlation_id] = command_id
      fact.metadata[:causation_id] = command_id
    end

    def vote_stream_name(event_id, user_id)
      "Vote$#{event_id}$#{user_id}"
    end

    def publish_to_streams(fact)
      main_stream    = fact.stream_names.first
      linked_streams = fact.stream_names[1..]

      event_store.publish(fact, stream_name: main_stream, expected_version: :none)
      linked_streams.each { |s| event_store.link(fact.event_id, stream_name: s) }
    end
  end
end
