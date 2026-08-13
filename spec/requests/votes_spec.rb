require 'rails_helper'

RSpec.describe 'Votes', type: :request do
  let(:event) { create(:event) }

  describe 'POST /votes' do
    context 'when not signed in' do
      before { sign_out }

      it 'redirects to root without dispatching any command' do
        expect(Rails.configuration.command_bus).not_to receive(:call)
        post '/votes', params: { event_id: event.external_id, vote_type: 'up' }
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when signed in' do
      before { sign_in_as(user_id: 'usr_test') }

      it 'redirects to events path after upvoting' do
        post '/votes', params: { event_id: event.external_id, vote_type: 'up' }
        expect(response).to redirect_to(events_path)
      end

      it 'redirects to events path after downvoting' do
        post '/votes', params: { event_id: event.external_id, vote_type: 'down' }
        expect(response).to redirect_to(events_path)
      end

      it 'dispatches UpvoteEvent for vote_type=up' do
        expect(Rails.configuration.command_bus)
          .to receive(:call).with(an_instance_of(Voting::UpvoteEvent))
        post '/votes', params: { event_id: event.external_id, vote_type: 'up' }
      end

      it 'dispatches DownvoteEvent for vote_type=down' do
        expect(Rails.configuration.command_bus)
          .to receive(:call).with(an_instance_of(Voting::DownvoteEvent))
        post '/votes', params: { event_id: event.external_id, vote_type: 'down' }
      end

      it 'returns 400 for an invalid vote_type' do
        post '/votes', params: { event_id: event.external_id, vote_type: 'sideways' }
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns 400 when vote_type is missing' do
        post '/votes', params: { event_id: event.external_id }
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end