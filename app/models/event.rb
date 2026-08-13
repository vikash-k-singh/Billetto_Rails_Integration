class Event < ApplicationRecord
  has_one :vote_count, dependent: :destroy
  has_many :applied_vote_facts, dependent: :destroy

  validates :title,       presence: true
  validates :starts_at,   presence: true
  validates :external_id, presence: true, uniqueness: true

  scope :available, -> { where(available: true) }
end
