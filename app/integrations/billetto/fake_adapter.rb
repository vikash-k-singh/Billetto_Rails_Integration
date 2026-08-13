module Billetto
  class FakeAdapter
    def fetch_all_events
      [
        EventData.new(
          external_id:    "fake-001",
          title:          "Fake Concert",
          description:    "A fake event for testing purposes",
          image_url:      "https://example.com/fake1.jpg",
          starts_at:      1.week.from_now,
          ends_at:        1.week.from_now + 2.hours,
          billetto_url:   "https://billetto.dk/e/fake-001",
          location:       "Test Venue, Test Street, Copenhagen, Denmark",
          organiser_name: "Test Organiser",
          available:      true
        )
      ]
    end
  end
end
