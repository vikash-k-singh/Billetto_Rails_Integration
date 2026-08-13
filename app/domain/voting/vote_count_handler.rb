module Voting
  class VoteCountHandler
    include Handler.async(queue: 'low')

    subscribes_to Voting::EventUpvoted, Voting::EventDownvoted

    def call(fact)
      event = Event.find_by!(external_id: fact.data[:event_id])
      count = VoteCount.find_or_create_by!(event: event)

      # with_lock acquires a row-level DB lock and re-reads the record,
      # preventing race conditions when multiple Sidekiq jobs run simultaneously.
      count.with_lock do
        case fact
        when Voting::EventUpvoted   then count.increment!(:upvotes)
        when Voting::EventDownvoted then count.increment!(:downvotes)
        end
      end
    end
  end
end