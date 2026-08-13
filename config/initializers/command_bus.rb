Rails.configuration.command_bus = Command::Bus.new

Rails.application.config.to_prepare do
  voting_service = Voting::Service.new
  Rails.configuration.command_bus.register(Voting::UpvoteEvent,   voting_service)
  Rails.configuration.command_bus.register(Voting::DownvoteEvent, voting_service)
end