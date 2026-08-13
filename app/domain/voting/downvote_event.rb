module Voting
  class DownvoteEvent
    include ActiveModel::Validations

    attr_accessor :event_id, :user_id

    validates :event_id, presence: true
    validates :user_id,  presence: true

    def initialize(event_id: nil, user_id: nil)
      @event_id = event_id
      @user_id  = user_id
    end
  end
end