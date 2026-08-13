require 'rails_helper'

RSpec.describe Voting::VoteCountHandler do
  subject(:handler) { described_class.new }

  let(:event) { create(:event) }

  def upvoted_fact
    Voting::EventUpvoted.strict(data: { event_id: event.external_id, user_id: 'usr-1' })
  end

  def downvoted_fact
    Voting::EventDownvoted.strict(data: { event_id: event.external_id, user_id: 'usr-1' })
  end

  describe '#call' do
    it 'increments upvotes when receiving EventUpvoted' do
      expect { handler.call(upvoted_fact) }
        .to change { VoteCount.find_or_create_by!(event: event).reload.upvotes }.by(1)
    end

    it 'increments downvotes when receiving EventDownvoted' do
      expect { handler.call(downvoted_fact) }
        .to change { VoteCount.find_or_create_by!(event: event).reload.downvotes }.by(1)
    end

    it 'creates a VoteCount record if one does not exist' do
      expect { handler.call(upvoted_fact) }.to change(VoteCount, :count).by(1)
    end

    it 'accumulates counts across multiple votes' do
      handler.call(upvoted_fact)
      handler.call(Voting::EventUpvoted.strict(data: { event_id: event.external_id, user_id: 'usr-2' }))
      handler.call(downvoted_fact)

      count = VoteCount.find_by!(event: event)
      expect(count.upvotes).to   eq(2)
      expect(count.downvotes).to eq(1)
    end
  end

  describe '.subscriptions' do
    it 'subscribes to EventUpvoted' do
      expect(described_class.subscriptions.keys).to include(Voting::EventUpvoted)
    end

    it 'subscribes to EventDownvoted' do
      expect(described_class.subscriptions.keys).to include(Voting::EventDownvoted)
    end
  end
end