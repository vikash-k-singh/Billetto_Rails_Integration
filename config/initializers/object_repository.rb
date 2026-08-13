Rails.application.config.to_prepare do
  ObjectRepository.register(Event)
end