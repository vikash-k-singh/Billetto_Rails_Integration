require 'rails_helper'

RSpec.describe Voting::DownvoteEvent do
  it 'is valid with both attributes' do
    expect(described_class.new(event_id: 'e1', user_id: 'u1')).to be_valid
  end

  it 'is invalid without event_id' do
    expect(described_class.new(user_id: 'u1')).not_to be_valid
  end

  it 'is invalid without user_id' do
    expect(described_class.new(event_id: 'e1')).not_to be_valid
  end
end
