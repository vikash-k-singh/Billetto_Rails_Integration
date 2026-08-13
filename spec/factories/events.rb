FactoryBot.define do
  factory :event do
    sequence(:external_id) { |n| "ext-#{n}" }
    title         { "Test Event" }
    description   { "A test event description" }
    starts_at     { 1.week.from_now }
    ends_at       { 1.week.from_now + 2.hours }
    image_url     { "https://example.com/image.jpg" }
    billetto_url  { "https://billetto.dk/e/test-event" }
    available     { true }
  end
end
