require 'rails_helper'

RSpec.describe Fact do
  let(:event_class) do
    Class.new(Fact) do
      const_set(:SCHEMA, { name: String, count: Integer }.freeze)

      def stream_names
        ["Test$#{data[:name]}"]
      end
    end
  end

  describe '.strict' do
    it 'creates a Fact with valid data' do
      fact = event_class.strict(data: { name: 'alpha', count: 3 })
      expect(fact.data[:name]).to eq('alpha')
      expect(fact.data[:count]).to eq(3)
    end

    it 'raises ArgumentError for missing keys' do
      expect { event_class.strict(data: { name: 'alpha' }) }
        .to raise_error(ArgumentError, /missing/)
    end

    it 'raises ArgumentError for unknown keys' do
      expect { event_class.strict(data: { name: 'alpha', count: 1, extra: 'x' }) }
        .to raise_error(ArgumentError, /unknown/)
    end

    it 'raises ArgumentError for wrong type' do
      expect { event_class.strict(data: { name: 'alpha', count: 'not_int' }) }
        .to raise_error(ArgumentError, /count must be Integer/)
    end

    it 'normalises string keys to symbols' do
      fact = event_class.strict(data: { 'name' => 'alpha', 'count' => 1 })
      expect(fact.data[:name]).to eq('alpha')
    end
  end

  describe '#stream_names' do
    it 'returns the correct stream name' do
      fact = event_class.strict(data: { name: 'alpha', count: 1 })
      expect(fact.stream_names).to eq(['Test$alpha'])
    end
  end
end