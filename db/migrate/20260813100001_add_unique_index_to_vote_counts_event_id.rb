class AddUniqueIndexToVoteCountsEventId < ActiveRecord::Migration[8.1]
  def up
    duplicate_event_ids = VoteCount.group(:event_id).having('COUNT(*) > 1').pluck(:event_id)
    duplicate_event_ids.each do |event_id|
      VoteCount.where(event_id: event_id).order(:id).offset(1).delete_all
    end

    remove_index :vote_counts, :event_id
    add_index :vote_counts, :event_id, unique: true
  end

  def down
    remove_index :vote_counts, :event_id
    add_index :vote_counts, :event_id
  end
end
