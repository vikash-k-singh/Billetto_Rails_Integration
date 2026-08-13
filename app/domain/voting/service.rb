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

      return if already_voted?(command.event_id, command.user_id)

      fact = fact_class.strict(data: { event_id: command.event_id, user_id: command.user_id })
      publish_to_streams(fact)
    rescue RubyEventStore::WrongExpectedEventVersion
      # Concurrent duplicate — safe to ignore
    end

    def already_voted?(event_id, user_id)
      event_store
        .read
        .stream("Voting$#{event_id}")
        .to_a
        .any? { |f| f.data[:user_id] == user_id }
    end

    def publish_to_streams(fact)
      main_stream    = fact.stream_names.first
      linked_streams = fact.stream_names[1..]

      event_store.publish(fact, stream_name: main_stream)
      linked_streams.each { |s| event_store.link(fact.event_id, stream_name: s) }
    end
  end
end