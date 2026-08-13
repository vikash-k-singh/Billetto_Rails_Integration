require 'rails_helper'

RSpec.describe Event, type: :model do
  subject { build(:event) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:starts_at) }
  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to validate_uniqueness_of(:external_id) }
  it { is_expected.to have_one(:vote_count) }
  it { is_expected.to have_many(:applied_vote_facts) }

  describe '.available' do
    it 'excludes unavailable events' do
      visible = create(:event, available: true)
      create(:event, available: false)
      expect(described_class.available).to contain_exactly(visible)
    end
  end
end
