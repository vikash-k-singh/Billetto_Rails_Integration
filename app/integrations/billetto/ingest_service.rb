module Billetto
  class IngestService
    Result = Struct.new(:success, :created, :updated, :errors, keyword_init: true)

    def initialize(adapter: nil)
      @adapter = adapter || Rails.configuration.billetto_adapter
    end

    def call
      events_data = @adapter.fetch_all_events
      fetched_ids = events_data.map(&:external_id)
      created = updated = errors = 0

      events_data.each do |data|
        record     = Event.find_or_initialize_by(external_id: data.external_id)
        new_record = record.new_record?

        record.assign_attributes(
          title: data.title, description: data.description,
          image_url: data.image_url, starts_at: data.starts_at,
          ends_at: data.ends_at, billetto_url: data.billetto_url,
          location: data.location, organiser_name: data.organiser_name,
          available: data.available
        )

        if record.save
          new_record ? created += 1 : updated += 1
        else
          errors += 1
          Rails.logger.warn("Failed to save event #{data.external_id}: #{record.errors.full_messages}")
        end
      end

      Event.where.not(external_id: fetched_ids).update_all(available: false)

      Result.new(success: true, created: created, updated: updated, errors: errors)
    rescue Billetto::Error => e
      Rails.logger.error("Billetto ingestion failed: #{e.message}")
      Result.new(success: false, created: 0, updated: 0, errors: 1)
    end
  end
end