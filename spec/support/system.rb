RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
    ActiveJob::Base.queue_adapter = :inline
  end
end
