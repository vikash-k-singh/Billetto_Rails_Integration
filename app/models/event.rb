class Event < ApplicationRecord
  has_one :vote_count, dependent: :destroy

  validates :title,       presence: true
  validates :starts_at,   presence: true
  validates :external_id, presence: true, uniqueness: true
end