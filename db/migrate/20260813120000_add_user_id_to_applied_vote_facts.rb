class AddUserIdToAppliedVoteFacts < ActiveRecord::Migration[8.1]
  def change
    add_column :applied_vote_facts, :user_id, :string

    reversible do |dir|
      dir.up do
        AppliedVoteFact.delete_all
        VoteCount.update_all(upvotes: 0, downvotes: 0)
      end
    end

    change_column_null :applied_vote_facts, :user_id, false
    add_index :applied_vote_facts, [ :event_id, :user_id ], unique: true
  end
end
