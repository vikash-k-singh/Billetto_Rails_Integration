require "rails_helper"

RSpec.describe ApplicationSubscriptions do
  it "updates the vote count when a subscribed fact is published" do
    event = create(:event)
    fact = Voting::EventUpvoted.strict(data: { event_id: event.external_id, user_id: "usr-1" })

    Rails.configuration.event_store.publish(fact, stream_name: fact.stream_names.first)

    expect(VoteCount.find_by!(event: event).upvotes).to eq(1)
  end

  it "does not register the same handler twice on a store" do
    store = RailsEventStore::Client.new
    described_class.register(store)
    described_class.register(store)

    event = create(:event)
    fact = Voting::EventUpvoted.strict(data: { event_id: event.external_id, user_id: "usr-2" })
    store.publish(fact, stream_name: fact.stream_names.first)

    expect(VoteCount.find_by!(event: event).upvotes).to eq(1)
  end
end
