class AddIndexToEventsStartsAt < ActiveRecord::Migration[8.1]
  def change
    add_index :events, :starts_at
    add_index :events, :available
  end
end
