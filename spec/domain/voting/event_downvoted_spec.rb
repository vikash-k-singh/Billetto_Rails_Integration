require 'rails_helper'

RSpec.describe Voting::EventDownvoted do
  it 'creates a fact with valid data' do
    fact = described_class.strict(data: { event_id: 'evt-2', user_id: 'usr-2' })
    expect(fact.data[:event_id]).to eq('evt-2')
  end

  describe '#stream_names' do
    subject(:fact) { described_class.strict(data: { event_id: 'evt-5', user_id: 'usr-9' }) }

    it 'has Voting$ as the primary stream' do
      expect(fact.stream_names.first).to eq('Voting$evt-5')
    end

    it 'has User$ as the linked stream' do
      expect(fact.stream_names.last).to eq('User$usr-9')
    end
  end
end