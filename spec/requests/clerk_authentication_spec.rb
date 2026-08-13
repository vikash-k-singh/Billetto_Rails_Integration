require 'rails_helper'

RSpec.describe 'Clerk authentication', type: :request do
  let!(:event) { create(:event) }

  it 'identifies the current user from a verified session token' do
    allow_any_instance_of(Clerk::SDK)
      .to receive(:verify_token)
      .with('valid-token')
      .and_return({ 'sub' => 'user_abc' })

    get '/events', headers: { 'Cookie' => '__session=valid-token' }
    expect(response.body).to include('aria-label="Upvote"')
    expect(response.body).to include("Sign Out")
  end

  it "treats an expired token as signed out" do
    allow_any_instance_of(Clerk::SDK)
      .to receive(:verify_token)
      .and_raise(JWT::ExpiredSignature.new("expired"))

    get "/events", headers: { "Cookie" => "__session=expired-token" }
    expect(response.body).to include("Sign In")
    expect(response.body).to include("Sign Up")
    expect(response.body).not_to include('aria-label="Upvote"')
  end

  it "treats a malformed token as signed out" do
    allow_any_instance_of(Clerk::SDK)
      .to receive(:verify_token)
      .and_raise(JWT::DecodeError.new("invalid"))

    get "/events", headers: { "Cookie" => "__session=bad-token" }
    expect(response.body).to include("Sign In")
    expect(response.body).not_to include('aria-label="Upvote"')
  end

  it 'does not call Clerk when no session token is present' do
    expect_any_instance_of(Clerk::SDK).not_to receive(:verify_token)
    get '/events'
    expect(response.body).to include('Sign In')
  end

  it 'rejects voting when the token is invalid' do
    allow_any_instance_of(Clerk::SDK)
      .to receive(:verify_token)
      .and_raise(JWT::DecodeError.new('invalid'))

    post '/votes', params: { event_id: event.external_id, vote_type: 'up' },
         headers: { 'Cookie' => '__session=bad-token' }
    expect(response).to redirect_to(root_path)
  end

  it 'filters Clerk handshake and session tokens from request logs' do
    allow_any_instance_of(Clerk::SDK)
      .to receive(:verify_token)
      .and_return({ 'sub' => 'user_abc' })

    get '/events', params: {
      '__clerk_handshake' => 'handshake-secret',
      '__clerk_db_jwt' => 'dev-browser-secret',
      'page' => '2'
    }

    expect(request.filtered_parameters['__clerk_handshake']).to eq('[FILTERED]')
    expect(request.filtered_parameters['__clerk_db_jwt']).to eq('[FILTERED]')
    expect(request.filtered_parameters['page']).to eq('2')
  end

  it 'redirects a Clerk handshake request to a clean URL so the next load can read the session cookie' do
    allow_any_instance_of(Clerk::SDK)
      .to receive(:verify_token)
      .and_return({ 'sub' => 'user_abc' })

    get '/events', params: { '__clerk_handshake' => 'handshake-token', 'page' => '2' }

    expect(response).to redirect_to('/events?page=2')
  end

  it 'reloads from the client when Clerk has a user but the server rendered signed out' do
    get '/events'

    expect(response.body).to include('clerk-auth-reload')
    expect(response.body).to include("window.location.replace")
  end

  it 'signs the user out and forgets the session cookie' do
    sign_in_as(user_id: 'user_abc')

    delete session_path

    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response.body).to include('Sign In')
    expect(response.body).not_to include('Sign Out')
  end
end
