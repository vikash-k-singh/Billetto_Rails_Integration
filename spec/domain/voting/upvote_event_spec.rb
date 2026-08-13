require 'rails_helper'

RSpec.describe Voting::UpvoteEvent do
  it 'is valid with both attributes' do
    expect(described_class.new(event_id: 'e1', user_id: 'u1')).to be_valid
  end

  it 'is invalid without event_id' do
    cmd = described_class.new(user_id: 'u1')
    expect(cmd).not_to be_valid
    expect(cmd.errors[:event_id]).to include("can't be blank")
  end

  it 'is invalid without user_id' do
    cmd = described_class.new(event_id: 'e1')
    expect(cmd).not_to be_valid
    expect(cmd.errors[:user_id]).to include("can't be blank")
  end

  it 'exposes event_id and user_id as attributes' do
    cmd = described_class.new(event_id: 'e1', user_id: 'u1')
    expect(cmd.event_id).to eq('e1')
    expect(cmd.user_id).to  eq('u1')
  end
end