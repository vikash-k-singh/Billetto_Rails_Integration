require 'rails_helper'

RSpec.describe VoteCount, type: :model do
  subject { build(:vote_count) }

  it { is_expected.to belong_to(:event) }
  it { is_expected.to validate_uniqueness_of(:event_id) }
  it { is_expected.to validate_numericality_of(:upvotes).is_greater_than_or_equal_to(0) }
  it { is_expected.to validate_numericality_of(:downvotes).is_greater_than_or_equal_to(0) }
end
