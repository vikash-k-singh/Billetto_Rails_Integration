module Voting
  class EventDownvoted < Fact
    SCHEMA = { event_id: String, user_id: String }.freeze

    def stream_names
      [
        "Vote$#{data[:event_id]}$#{data[:user_id]}",
        "Voting$#{data[:event_id]}",
        "User$#{data[:user_id]}"
      ]
    end
  end
end
