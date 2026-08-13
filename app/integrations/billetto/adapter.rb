module Billetto
  class Adapter
    def initialize(client: nil)
      @client = client || Client.new
    end

    def fetch_all_events
      results = []
      after   = nil

      loop do
        page = @client.list_events(after: after)
        results.concat(page.fetch('data', []).map { |raw| map_event(raw) })
        break unless page['has_more']

        after = extract_cursor(page['next_url'])
      end

      results
    end

    private

    def map_event(raw)
      EventData.new(
        external_id:    raw['id'],
        title:          raw['title'],
        description:    sanitize(raw['description']),
        image_url:      raw['image_link'],
        starts_at:      Time.parse(raw['startdate']),
        ends_at:        raw['enddate'] ? Time.parse(raw['enddate']) : nil,
        billetto_url:   raw['url'],
        location:       build_location(raw['location']),
        organiser_name: raw.dig('organiser', 'name'),
        available:      raw['availability']
      )
    end

    def build_location(loc)
      return nil unless loc

      [loc['location_name'], loc['address_line'], loc['city'], loc['country']]
        .reject(&:blank?)
        .join(', ')
    end

    def sanitize(text)
      return nil unless text

      stripped = ActionController::Base.helpers.strip_tags(text)
      CGI.unescapeHTML(stripped)
    end

    def extract_cursor(next_url)
      return nil unless next_url

      URI.decode_www_form(URI.parse(next_url).query.to_s).to_h['after']
    end
  end
end