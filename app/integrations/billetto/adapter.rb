module Billetto
  class Adapter
    MAX_PAGES = 100

    def initialize(client: nil)
      @client = client || Client.new
    end

    def fetch_all_events
      results = []
      after   = nil
      pages   = 0

      loop do
        pages += 1
        raise ApiError, "Pagination exceeded #{MAX_PAGES} pages" if pages > MAX_PAGES

        page = @client.list_events(after: after)
        raise MalformedResponseError, "Expected a JSON object" unless page.is_a?(Hash)

        data = page["data"]
        raise MalformedResponseError, "Expected data array" unless data.is_a?(Array)

        data.each do |raw|
          mapped = map_event(raw)
          results << mapped if mapped
        end

        break unless page["has_more"]

        next_after = extract_cursor(page["next_url"])
        break if next_after.blank? || next_after == after

        after = next_after
      end

      results
    end

    private

    def map_event(raw)
      return nil unless raw.is_a?(Hash)
      return nil if raw["id"].blank? || raw["title"].blank? || raw["startdate"].blank?

      starts_at = parse_time(raw["startdate"])
      return nil unless starts_at

      EventData.new(
        external_id:    raw["id"].to_s,
        title:          raw["title"],
        description:    sanitize(raw["description"]),
        image_url:      raw["image_link"],
        starts_at:      starts_at,
        ends_at:        parse_time(raw["enddate"]),
        billetto_url:   raw["url"],
        location:       build_location(raw["location"]),
        organiser_name: raw.dig("organiser", "name"),
        available:      available?(raw["availability"])
      )
    rescue ArgumentError, TypeError
      nil
    end

    def parse_time(value)
      return nil if value.blank?

      Time.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def available?(value)
      value == true || value.to_s == "available"
    end

    def build_location(loc)
      return nil unless loc.is_a?(Hash)

      [ loc["location_name"], loc["address_line"], loc["city"], loc["country"] ]
        .reject(&:blank?)
        .join(", ")
        .presence
    end

    def sanitize(text)
      return nil unless text

      stripped = ActionController::Base.helpers.strip_tags(text.to_s)
      CGI.unescapeHTML(stripped)
    end

    def extract_cursor(next_url)
      return nil unless next_url

      URI.decode_www_form(URI.parse(next_url).query.to_s).to_h["after"]
    rescue URI::InvalidURIError
      nil
    end
  end
end
