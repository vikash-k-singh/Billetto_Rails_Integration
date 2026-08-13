require 'rails_helper'

RSpec.describe Billetto::Adapter do
  subject(:adapter) { described_class.new(client: fake_client) }

  let(:raw_event) do
    {
      'id'           => '1001',
      'title'        => 'Jazz Night',
      'description'  => 'Great jazz &amp; fun<br>come along',
      'image_link'   => 'https://img.example.com/jazz.jpg',
      'startdate'    => '2026-07-01T19:00:00Z',
      'enddate'      => '2026-07-01T22:00:00Z',
      'url'          => 'https://billetto.dk/e/jazz',
      'availability' => true,
      'organiser'    => { 'name' => 'Jazz Club' },
      'location'     => {
        'location_name' => 'Blue Note',
        'address_line'  => 'Jazzgade 1',
        'city'          => 'Copenhagen',
        'country'       => 'Denmark'
      }
    }
  end

  let(:fake_client) do
    double('client').tap do |c|
      allow(c).to receive(:list_events)
        .and_return({ 'data' => [ raw_event ], 'has_more' => false })
    end
  end

  describe '#fetch_all_events' do
    it 'returns an array of EventData structs' do
      expect(adapter.fetch_all_events.first).to be_a(Billetto::EventData)
    end

    it 'maps external_id from the id field' do
      expect(adapter.fetch_all_events.first.external_id).to eq('1001')
    end

    it 'parses starts_at from startdate' do
      expect(adapter.fetch_all_events.first.starts_at).to eq(Time.parse('2026-07-01T19:00:00Z'))
    end

    it 'strips HTML tags and decodes entities from description' do
      desc = adapter.fetch_all_events.first.description
      expect(desc).not_to include('<br>')
      expect(desc).to include('&')
    end

    it 'builds a location string from nested fields' do
      expect(adapter.fetch_all_events.first.location)
        .to eq('Blue Note, Jazzgade 1, Copenhagen, Denmark')
    end

    it 'omits blank location_name from the location string' do
      raw_event['location']['location_name'] = ''
      expect(adapter.fetch_all_events.first.location)
        .to eq('Jazzgade 1, Copenhagen, Denmark')
    end

    it 'follows pagination until has_more is false' do
      allow(fake_client).to receive(:list_events).with(after: nil)
        .and_return({ 'data' => [ raw_event ], 'has_more' => true,
                      'next_url' => '/api/v3/public/events?after=1001&limit=25' })
      allow(fake_client).to receive(:list_events).with(after: '1001')
        .and_return({ 'data' => [], 'has_more' => false })

      adapter.fetch_all_events
      expect(fake_client).to have_received(:list_events).twice
    end

    it 'stops pagination when has_more is true but next_url has no cursor' do
      allow(fake_client).to receive(:list_events)
        .and_return({ 'data' => [ raw_event ], 'has_more' => true, 'next_url' => nil })

      expect(adapter.fetch_all_events.size).to eq(1)
      expect(fake_client).to have_received(:list_events).once
    end

    it 'skips malformed events instead of failing the batch' do
      raw_event['startdate'] = 'not-a-date'
      expect(adapter.fetch_all_events).to eq([])
    end

    it 'raises MalformedResponseError when the page is not a hash' do
      allow(fake_client).to receive(:list_events).and_return('oops')
      expect { adapter.fetch_all_events }.to raise_error(Billetto::MalformedResponseError)
    end

    it 'raises MalformedResponseError when data is not an array' do
      allow(fake_client).to receive(:list_events).and_return({ 'data' => 'nope', 'has_more' => false })
      expect { adapter.fetch_all_events }.to raise_error(Billetto::MalformedResponseError)
    end
  end
end
