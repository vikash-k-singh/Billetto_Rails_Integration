class VotesController < ApplicationController
  before_action :authenticate_user!

  def create
    command_bus.call(
      vote_command.new(
        event_id: params[:event_id],
        user_id:  current_user.id
      )
    )
    redirect_to events_path
  end

  private

  def vote_command
    case params[:vote_type]&.downcase
    when 'up'   then Voting::UpvoteEvent
    when 'down' then Voting::DownvoteEvent
    else raise ActionController::BadRequest, 'invalid vote_type'
    end
  end
end