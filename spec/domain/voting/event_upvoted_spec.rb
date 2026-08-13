require 'rails_helper'

RSpec.describe Voting::EventUpvoted do
  describe '.strict' do
    it 'creates a fact with valid data' do
      fact = described_class.strict(data: { event_id: 'evt-1', user_id: 'usr-1' })
      expect(fact.data[:event_id]).to eq('evt-1')
      expect(fact.data[:user_id]).to  eq('usr-1')
    end

    it 'raises ArgumentError for missing user_id' do
      expect { described_class.strict(data: { event_id: 'evt-1' }) }
        .to raise_error(ArgumentError, /missing/)
    end

    it 'raises ArgumentError for unknown keys' do
      expect { described_class.strict(data: { event_id: 'e', user_id: 'u', extra: 'x' }) }
        .to raise_error(ArgumentError, /unknown/)
    end
  end

  describe '#stream_names' do
    subject(:fact) { described_class.strict(data: { event_id: 'evt-42', user_id: 'usr-7' }) }

    it 'uses Vote$event$user as the uniqueness stream' do
      expect(fact.stream_names.first).to eq('Vote$evt-42$usr-7')
    end

    it 'links the Voting$ stream' do
      expect(fact.stream_names).to include('Voting$evt-42')
    end

    it 'links the User$ stream' do
      expect(fact.stream_names.last).to eq('User$usr-7')
    end
  end
end
