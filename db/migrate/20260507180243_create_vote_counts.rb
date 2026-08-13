class CreateVoteCounts < ActiveRecord::Migration[8.1]
  def change
    create_table :vote_counts do |t|
      t.references :event, null: false, foreign_key: true
      t.integer :upvotes,   null: false, default: 0
      t.integer :downvotes, null: false, default: 0

      t.timestamps
    end
  end
end