module ClerkHelpers
  def sign_in_as(user_id: 'test_user_001')
    allow_any_instance_of(Clerk::SDK)
      .to receive(:verify_token)
      .and_return({ 'sub' => user_id })
    cookies[:__session] = 'test-session-token'
  end

  def sign_out
    cookies.delete(:__session)
  end
end

RSpec.configure do |config|
  config.include ClerkHelpers, type: :request
end
