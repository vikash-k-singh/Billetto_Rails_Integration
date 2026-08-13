require "rails_helper"

RSpec.describe Voting::VoteCountRebuilder do
  subject(:rebuilder) { described_class.new }

  let(:event) { create(:event) }
  let(:other) { create(:event) }

  def upvote(target, user_id)
    Rails.configuration.command_bus.call(
      Voting::UpvoteEvent.new(event_id: target.external_id, user_id: user_id)
    )
  end

  def downvote(target, user_id)
    Rails.configuration.command_bus.call(
      Voting::DownvoteEvent.new(event_id: target.external_id, user_id: user_id)
    )
  end

  it "rebuilds from scratch after the projection is cleared" do
    upvote(event, "usr-1")
    VoteCount.delete_all
    AppliedVoteFact.delete_all

    rebuilder.call

    expect(event.reload.vote_count.upvotes).to eq(1)
    expect(event.vote_count.downvotes).to eq(0)
  end

  it "rebuilds upvotes and downvotes" do
    upvote(event, "usr-1")
    downvote(event, "usr-2")

    rebuilder.call

    expect(event.reload.vote_count.upvotes).to eq(1)
    expect(event.vote_count.downvotes).to eq(1)
  end

  it "rebuilds counts for multiple events" do
    upvote(event, "usr-1")
    upvote(other, "usr-2")
    upvote(other, "usr-3")

    rebuilder.call

    expect(event.reload.vote_count.upvotes).to eq(1)
    expect(other.reload.vote_count.upvotes).to eq(2)
  end

  it "does not double-count when the same facts are replayed" do
    upvote(event, "usr-1")
    fact = Rails.configuration.event_store.read.stream("Voting$#{event.external_id}").first
    Voting::VoteCountHandler.new.call(fact)

    rebuilder.call

    expect(event.reload.vote_count.upvotes).to eq(1)
  end

  it "is idempotent when run twice" do
    upvote(event, "usr-1")
    downvote(event, "usr-2")

    rebuilder.call
    first = event.reload.vote_count.attributes.slice("upvotes", "downvotes")
    rebuilder.call

    expect(event.reload.vote_count.attributes.slice("upvotes", "downvotes")).to eq(first)
  end

  it "leaves no vote counts when the event store has no vote facts" do
    create(:vote_count, event: event, upvotes: 4, downvotes: 1)

    rebuilder.call

    expect(VoteCount.count).to eq(0)
    expect(AppliedVoteFact.count).to eq(0)
  end

  it "does not create a vote count for an event with no votes" do
    create(:event)
    upvote(event, "usr-1")

    rebuilder.call

    expect(VoteCount.where(event: other)).not_to exist
    expect(event.reload.vote_count.upvotes).to eq(1)
  end

  it "can rebuild a single event from its Voting$ stream" do
    upvote(event, "usr-1")
    upvote(other, "usr-2")
    VoteCount.delete_all
    AppliedVoteFact.delete_all

    rebuilder.call(external_id: event.external_id)

    expect(event.reload.vote_count.upvotes).to eq(1)
    expect(VoteCount.where(event: other)).not_to exist
  end
end
