class VoteCount < ApplicationRecord
  belongs_to :event

  validates :event_id, uniqueness: true
  validates :upvotes,   numericality: { greater_than_or_equal_to: 0 }
  validates :downvotes, numericality: { greater_than_or_equal_to: 0 }
end
