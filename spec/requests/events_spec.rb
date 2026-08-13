require 'rails_helper'

RSpec.describe 'Events', type: :request do
  let!(:event)      { create(:event, title: 'Jazz Night', starts_at: 1.day.from_now) }
  let!(:vote_count) { create(:vote_count, event: event, upvotes: 3, downvotes: 1) }

  describe 'GET /events' do
    it 'returns HTTP 200' do
      get '/events'
      expect(response).to have_http_status(:ok)
    end

    it 'displays the event title' do
      get '/events'
      expect(response.body).to include('Jazz Night')
    end

    it 'displays vote counts' do
      get '/events'
      expect(response.body).to include('3')
      expect(response.body).to include('1')
    end

    it 'is publicly accessible without authentication' do
      get '/events'
      expect(response).to have_http_status(:ok)
    end
  end
end