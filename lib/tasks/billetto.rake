namespace :billetto do
  desc "Fetch and ingest events from the Billetto API"
  task ingest: :environment do
    result = Billetto::IngestService.new.call

    if result.success
      puts "Ingestion complete — created: #{result.created}, updated: #{result.updated}, errors: #{result.errors}"
    else
      warn "Ingestion failed — check Rails logs for details"
      exit 1
    end
  end
end