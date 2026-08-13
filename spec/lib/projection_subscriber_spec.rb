require "rails_helper"

RSpec.describe ProjectionSubscriber do
  it "applies the handler synchronously" do
    event = create(:event)
    fact = Voting::EventUpvoted.strict(data: { event_id: event.external_id, user_id: "usr-1" })

    described_class.new(Voting::VoteCountHandler).call(fact)

    expect(VoteCount.find_by!(event: event).upvotes).to eq(1)
  end
end
