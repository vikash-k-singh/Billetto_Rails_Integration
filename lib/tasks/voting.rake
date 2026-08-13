namespace :voting do
  desc "Rebuild vote_counts from EventUpvoted and EventDownvoted facts"
  task :rebuild_vote_counts, [ :external_id ] => :environment do |_task, args|
    Voting::VoteCountRebuilder.new.call(external_id: args[:external_id].presence)
    puts "Vote counts rebuilt"
  end
end
