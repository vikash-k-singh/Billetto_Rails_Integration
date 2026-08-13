require 'rails_helper'

RSpec.describe Voting::Service do
  subject(:service) { described_class.new }

  let(:event)   { create(:event) }
  let(:user_id) { 'clerk_user_001' }

  def upvote_cmd   = Voting::UpvoteEvent.new(event_id: event.external_id, user_id: user_id)
  def downvote_cmd = Voting::DownvoteEvent.new(event_id: event.external_id, user_id: user_id)

  def voting_stream
    Rails.configuration.event_store.read.stream("Voting$#{event.external_id}").to_a
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
  end

  describe 'concurrent duplicate prevention' do
    it 'treats WrongExpectedEventVersion as a no-op' do
      allow(Rails.configuration.event_store).to receive(:publish)
        .and_raise(RubyEventStore::WrongExpectedEventVersion)
      expect { service.call(upvote_cmd) }.not_to raise_error
    end
  end

  describe 'non-existent event' do
    it 'raises ActiveRecord::RecordNotFound' do
      cmd = Voting::UpvoteEvent.new(event_id: 'does-not-exist', user_id: user_id)
      expect { service.call(cmd) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end