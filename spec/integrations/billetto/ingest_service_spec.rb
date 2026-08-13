require 'rails_helper'

RSpec.describe Billetto::IngestService do
  subject(:service) { described_class.new(adapter: fake_adapter) }

  let(:event_data) do
    Billetto::EventData.new(
      external_id: 'ext-100', title: 'Test Concert',
      description: 'Great music', image_url: 'https://example.com/img.jpg',
      starts_at: 1.week.from_now, ends_at: 1.week.from_now + 2.hours,
      billetto_url: 'https://billetto.dk/e/ext-100',
      location: 'Venue, City, Country', organiser_name: 'Org', available: true
    )
  end

  let(:fake_adapter) { double('adapter', fetch_all_events: [event_data]) }

  describe '#call' do
    it 'creates a new Event record' do
      expect { service.call }.to change(Event, :count).by(1)
    end

    it 'sets the correct title on the created event' do
      service.call
      expect(Event.find_by(external_id: 'ext-100').title).to eq('Test Concert')
    end

    it 'updates an existing event on re-ingestion' do
      create(:event, external_id: 'ext-100', title: 'Old Title')
      service.call
      expect(Event.find_by(external_id: 'ext-100').title).to eq('Test Concert')
    end

    it 'marks events absent from the latest fetch as unavailable' do
      stale = create(:event, external_id: 'stale-999', available: true)
      service.call
      expect(stale.reload.available).to be false
    end

    it 'does not mark freshly fetched events as unavailable' do
      create(:event, external_id: 'ext-100', available: true)
      service.call
      expect(Event.find_by(external_id: 'ext-100').available).to be true
    end

    it 'returns a successful result with created count' do
      result = service.call
      expect(result.success).to be true
      expect(result.created).to eq(1)
    end

    it 'returns a failed result when the adapter raises an API error' do
      allow(fake_adapter).to receive(:fetch_all_events)
        .and_raise(Billetto::ApiError, 'connection failed')
      result = service.call
      expect(result.success).to be false
    end
  end
end