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

      it "redirects to events path after an HTML upvote" do
        post "/votes", params: { event_id: event.external_id, vote_type: "up" }
        expect(response).to redirect_to(events_path)
      end

      it "replaces only the vote counts for a turbo stream upvote" do
        post "/votes", params: { event_id: event.external_id, vote_type: "up" }, as: :turbo_stream
        expect(response.media_type).to eq(Mime[:turbo_stream])
        expect(response.body).to include("👍 1")
        expect(response).not_to have_http_status(:redirect)
      end

      it "redirects to events path after an HTML downvote" do
        post "/votes", params: { event_id: event.external_id, vote_type: "down" }
        expect(response).to redirect_to(events_path)
      end

      it 'publishes EventUpvoted for vote_type=up' do
        post '/votes', params: { event_id: event.external_id, vote_type: 'up' }
        events = Rails.configuration.event_store.read.stream("Voting$#{event.external_id}").to_a
        expect(events.map(&:class)).to include(Voting::EventUpvoted)
        expect(events.first.data[:user_id]).to eq('usr_test')
      end

      it 'publishes EventDownvoted for vote_type=down' do
        post '/votes', params: { event_id: event.external_id, vote_type: 'down' }
        events = Rails.configuration.event_store.read.stream("Voting$#{event.external_id}").to_a
        expect(events.map(&:class)).to include(Voting::EventDownvoted)
        expect(events.first.data[:user_id]).to eq('usr_test')
      end

      it "updates the vote count read model" do
        post "/votes", params: { event_id: event.external_id, vote_type: "up" }
        expect(event.reload.vote_count.upvotes).to eq(1)
      end

      it "counts a single vote when the same user posts twice" do
        2.times do
          post "/votes", params: { event_id: event.external_id, vote_type: "up" }, as: :turbo_stream
        end
        expect(event.reload.vote_count.upvotes).to eq(1)
      end

      it "repairs a missed projection on a later turbo stream vote" do
        post "/votes", params: { event_id: event.external_id, vote_type: "up" }, as: :turbo_stream
        VoteCount.delete_all
        AppliedVoteFact.delete_all

        post "/votes", params: { event_id: event.external_id, vote_type: "up" }, as: :turbo_stream

        expect(response.body).to include("👍 1")
        expect(event.reload.vote_count.upvotes).to eq(1)
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

      it 'redirects with an alert when the event does not exist' do
        post '/votes', params: { event_id: 'missing-event', vote_type: 'up' }
        expect(response).to redirect_to(events_path)
        expect(flash[:alert]).to eq('Event not found.')
      end

      it 'redirects with an alert when the command is invalid' do
        post '/votes', params: { event_id: '', vote_type: 'up' }
        expect(response).to redirect_to(events_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
