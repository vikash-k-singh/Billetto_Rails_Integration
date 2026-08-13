module ClerkHelpers
  def sign_in_as(user_id: 'test_user_001')
    allow_any_instance_of(ApplicationController)
      .to receive(:clerk_session_user)
      .and_return(OpenStruct.new(id: user_id))
  end

  def sign_out
    allow_any_instance_of(ApplicationController)
      .to receive(:clerk_session_user)
      .and_return(nil)
  end
end

RSpec.configure do |config|
  config.include ClerkHelpers, type: :request
end