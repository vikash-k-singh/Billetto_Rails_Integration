class EventsController < ApplicationController
  PER_PAGE = 25

  def index
    @page = [ params.fetch(:page, 1).to_i, 1 ].max
    @events = Event.available
                   .includes(:vote_count)
                   .order(starts_at: :asc)
                   .limit(PER_PAGE)
                   .offset((@page - 1) * PER_PAGE)
    @has_next = Event.available.offset(@page * PER_PAGE).exists?
  end
end
