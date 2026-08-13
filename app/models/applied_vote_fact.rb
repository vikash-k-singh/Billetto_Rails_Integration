class AppliedVoteFact < ApplicationRecord
  belongs_to :event

  validates :fact_id, presence: true, uniqueness: true
  validates :fact_type, presence: true
  validates :user_id, presence: true
  validates :user_id, uniqueness: { scope: :event_id }
end
