RSpec.describe VoteCount, type: :model do
  it { is_expected.to belong_to(:event) }
  it { is_expected.to validate_numericality_of(:upvotes).is_greater_than_or_equal_to(0) }
  it { is_expected.to validate_numericality_of(:downvotes).is_greater_than_or_equal_to(0) }
end