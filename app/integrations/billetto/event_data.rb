module Billetto
  EventData = Struct.new(
    :external_id, :title, :description, :image_url,
    :starts_at, :ends_at, :billetto_url, :location,
    :organiser_name, :available,
    keyword_init: true
  )
end