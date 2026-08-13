module Voting
  class VoteCountHandler
    include Handler.async(queue: "low")

    subscribes_to Voting::EventUpvoted, Voting::EventDownvoted

    def call(fact)
      event = Event.find_by!(external_id: fact.data[:event_id])
      claim_vote!(fact, event)
      refresh_counts!(event)
    end

    private

    def claim_vote!(fact, event)
      AppliedVoteFact.insert_all(
        [ {
          fact_id: fact.event_id,
          event_id: event.id,
          user_id: fact.data[:user_id],
          fact_type: fact.class.name,
          created_at: Time.current,
          updated_at: Time.current
        } ],
        unique_by: %i[event_id user_id]
      )
    end

    def refresh_counts!(event)
      count = find_or_create_count(event)
      count.with_lock do
        count.update!(
          upvotes: AppliedVoteFact.where(event_id: event.id, fact_type: EventUpvoted.name).count,
          downvotes: AppliedVoteFact.where(event_id: event.id, fact_type: EventDownvoted.name).count
        )
      end
    end

    def find_or_create_count(event)
      VoteCount.insert_all(
        [ {
          event_id: event.id,
          upvotes: 0,
          downvotes: 0,
          created_at: Time.current,
          updated_at: Time.current
        } ],
        unique_by: :event_id
      )
      VoteCount.find_by!(event_id: event.id)
    end
  end
end
