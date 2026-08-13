class CreateAppliedVoteFacts < ActiveRecord::Migration[8.1]
  def change
    create_table :applied_vote_facts do |t|
      t.uuid :fact_id, null: false
      t.references :event, null: false, foreign_key: true
      t.string :fact_type, null: false

      t.timestamps
    end

    add_index :applied_vote_facts, :fact_id, unique: true
  end
end
