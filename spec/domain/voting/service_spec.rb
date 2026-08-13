require 'rails_helper'

RSpec.describe Voting::Service do
  subject(:service) { described_class.new }

  let(:event)   { create(:event) }
  let(:user_id) { 'clerk_user_001' }

  def upvote_cmd(uid = user_id)
    Voting::UpvoteEvent.new(event_id: event.external_id, user_id: uid)
  end

  def downvote_cmd(uid = user_id)
    Voting::DownvoteEvent.new(event_id: event.external_id, user_id: uid)
  end

  def voting_stream
    Rails.configuration.event_store.read.stream("Voting$#{event.external_id}").to_a
  end

  def vote_stream(uid = user_id)
    Rails.configuration.event_store.read.stream("Vote$#{event.external_id}$#{uid}").to_a
  end

  describe 'upvoting' do
    it 'publishes EventUpvoted to the Voting$ stream' do
      service.call(upvote_cmd)
      expect(voting_stream).to include(an_object_having_attributes(class: Voting::EventUpvoted))
    end

    it 'stores the user_id in the fact data' do
      service.call(upvote_cmd)
      expect(voting_stream.first.data[:user_id]).to eq(user_id)
    end

    it 'publishes to the Vote$ uniqueness stream with expected_version :none' do
      expect(Rails.configuration.event_store).to receive(:publish).with(
        an_instance_of(Voting::EventUpvoted),
        hash_including(stream_name: "Vote$#{event.external_id}$#{user_id}", expected_version: :none)
      ).and_call_original

      service.call(upvote_cmd)
    end
  end

  describe 'downvoting' do
    it 'publishes EventDownvoted to the Voting$ stream' do
      service.call(downvote_cmd)
      expect(voting_stream).to include(an_object_having_attributes(class: Voting::EventDownvoted))
    end
  end

  describe 'one vote per user per event' do
    it 'does not publish a second upvote for the same user' do
      service.call(upvote_cmd)
      expect { service.call(upvote_cmd) }.not_to change { voting_stream.count }
    end

    it 'does not allow switching direction (upvote then downvote)' do
      service.call(upvote_cmd)
      expect { service.call(downvote_cmd) }.not_to change { voting_stream.count }
    end

    it 'allows different users to vote on the same event' do
      service.call(upvote_cmd('user_a'))
      service.call(upvote_cmd('user_b'))
      expect(voting_stream.count).to eq(2)
    end

    it 'repairs the vote count when the fact exists but the read model was missed' do
      service.call(upvote_cmd)
      VoteCount.delete_all
      AppliedVoteFact.delete_all

      service.call(upvote_cmd)

      expect(voting_stream.count).to eq(1)
      expect(event.reload.vote_count.upvotes).to eq(1)
    end
  end

  describe 'concurrent duplicate prevention' do
    it 'treats WrongExpectedEventVersion as a no-op' do
      allow(Rails.configuration.event_store).to receive(:publish)
        .and_raise(RubyEventStore::WrongExpectedEventVersion)
      expect { service.call(upvote_cmd) }.not_to raise_error
      expect(vote_stream).to be_empty
    end
  end

  describe 'non-existent event' do
    it 'raises ActiveRecord::RecordNotFound' do
      cmd = Voting::UpvoteEvent.new(event_id: 'does-not-exist', user_id: user_id)
      expect { service.call(cmd) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
