FactoryBot.define do
  factory :vote_count do
    association :event
    upvotes   { 0 }
    downvotes { 0 }
  end
end
