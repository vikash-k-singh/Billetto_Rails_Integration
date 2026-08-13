require 'rails_helper'

RSpec.describe Event, type: :model do
  subject { build(:event) }
  
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:starts_at) }
  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to validate_uniqueness_of(:external_id) }
  it { is_expected.to have_one(:vote_count) }
end