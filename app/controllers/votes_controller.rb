class VotesController < ApplicationController
  before_action :authenticate_user!

  def create
    command_bus.call(
      vote_command.new(
        event_id: params[:event_id],
        user_id: current_user.id
      )
    )
    @event = Event.find_by!(external_id: params[:event_id])
    @event.association(:vote_count).reset

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to events_path }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to events_path, alert: "Event not found."
  rescue Command::Invalid => e
    redirect_to events_path, alert: e.message
  end

  private

  def vote_command
    case params[:vote_type]&.downcase
    when "up"   then Voting::UpvoteEvent
    when "down" then Voting::DownvoteEvent
    else raise ActionController::BadRequest, "invalid vote_type"
    end
  end
end
