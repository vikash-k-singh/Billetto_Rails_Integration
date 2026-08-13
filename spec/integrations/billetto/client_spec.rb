require 'rails_helper'

RSpec.describe Billetto::Client do
  subject(:client) do
    described_class.new(access_key_id: 'TEST_ID', access_key_secret: 'TEST_SECRET')
  end

  let(:events_url) { 'https://billetto.dk/api/v3/public/events' }

  let(:success_body) do
    {
      object: 'list',
      data: [{
        id: '123', title: 'Test Event',
        startdate: '2026-06-01T10:00:00Z', enddate: '2026-06-01T12:00:00Z',
        description: 'A description', image_link: 'https://img.example.com/1.jpg',
        url: 'https://billetto.dk/e/test', availability: true,
        organiser: { id: 1, name: 'Org' },
        location: { location_name: 'Hall', address_line: 'Main St',
                    city: 'Copenhagen', country: 'Denmark' }
      }],
      has_more: false, total: 1
    }.to_json
  end

  describe '#list_events' do
    it 'uses HTTP Basic Auth and returns parsed JSON' do
      stub_request(:get, events_url)
        .with(
          headers: { 'Authorization' => /\ABasic / },
          query: hash_including({})
        )
        .to_return(status: 200, body: success_body,
                 headers: { 'Content-Type' => 'application/json' })

      result = client.list_events
      expect(result['data'].first['id']).to eq('123')
    end

    it 'passes the after cursor when provided' do
      stub_request(:get, events_url)
        .with(query: hash_including('after' => '999'))
        .to_return(status: 200, body: success_body,
                   headers: { 'Content-Type' => 'application/json' })

      expect { client.list_events(after: '999') }.not_to raise_error
    end

    it 'raises AuthenticationError on 401' do
      stub_request(:get, events_url)
        .with(query: hash_including({}))
        .to_return(status: 401, body: 'Unauthorized')
      expect { client.list_events }.to raise_error(Billetto::AuthenticationError)
    end

    it 'raises RateLimitError on 429' do
      stub_request(:get, events_url)
        .with(query: hash_including({}))
        .to_return(status: 429, body: 'Too Many Requests')
      expect { client.list_events }.to raise_error(Billetto::RateLimitError)
    end

    it 'raises ApiError on other non-2xx responses' do
      stub_request(:get, events_url)
        .with(query: hash_including({}))
        .to_return(status: 500, body: 'Server Error')
      expect { client.list_events }.to raise_error(Billetto::ApiError)
    end
  end
end