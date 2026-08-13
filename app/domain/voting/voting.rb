module Voting
  def self.subscriptions
    [
      VoteCountHandler.subscriptions
    ].reduce(&:merge)
  end
end
