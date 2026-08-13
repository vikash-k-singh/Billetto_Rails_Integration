require 'rails_helper'

RSpec.describe 'Events', type: :request do
  let!(:event)      { create(:event, title: 'Jazz Night', starts_at: 1.day.from_now, description: 'Great jazz') }
  let!(:vote_count) { create(:vote_count, event: event, upvotes: 3, downvotes: 1) }

  describe 'GET /events' do
    it 'returns HTTP 200' do
      get '/events'
      expect(response).to have_http_status(:ok)
    end

    it 'displays the event title, date, image, and description' do
      get '/events'
      expect(response.body).to include('Jazz Night')
      expect(response.body).to include(event.starts_at.strftime('%d %b %Y'))
      expect(response.body).to include(event.image_url)
      expect(response.body).to include('Great jazz')
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

    it 'does not display unavailable events' do
      create(:event, title: 'Hidden Show', available: false)
      get '/events'
      expect(response.body).not_to include('Hidden Show')
    end

    it 'paginates events' do
      create_list(:event, EventsController::PER_PAGE, starts_at: 2.days.from_now)
      get '/events', params: { page: 2 }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Previous')
    end
  end
end
