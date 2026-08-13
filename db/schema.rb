# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_13_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "applied_vote_facts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.uuid "fact_id", null: false
    t.string "fact_type", null: false
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index ["event_id", "user_id"], name: "index_applied_vote_facts_on_event_id_and_user_id", unique: true
    t.index ["event_id"], name: "index_applied_vote_facts_on_event_id"
    t.index ["fact_id"], name: "index_applied_vote_facts_on_fact_id", unique: true
  end

  create_table "event_store_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.binary "data", null: false
    t.uuid "event_id", null: false
    t.string "event_type", null: false
    t.binary "metadata"
    t.datetime "valid_at"
    t.index ["created_at"], name: "index_event_store_events_on_created_at"
    t.index ["event_id"], name: "index_event_store_events_on_event_id", unique: true
    t.index ["event_type"], name: "index_event_store_events_on_event_type"
    t.index ["valid_at"], name: "index_event_store_events_on_valid_at"
  end

  create_table "event_store_events_in_streams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "event_id", null: false
    t.integer "position"
    t.string "stream", null: false
    t.index ["created_at"], name: "index_event_store_events_in_streams_on_created_at"
    t.index ["event_id"], name: "index_event_store_events_in_streams_on_event_id"
    t.index ["stream", "event_id"], name: "index_event_store_events_in_streams_on_stream_and_event_id", unique: true
    t.index ["stream", "position"], name: "index_event_store_events_in_streams_on_stream_and_position", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.boolean "available", default: true, null: false
    t.string "billetto_url"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "ends_at"
    t.string "external_id", null: false
    t.string "image_url"
    t.string "location"
    t.string "organiser_name"
    t.datetime "starts_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["available"], name: "index_events_on_available"
    t.index ["external_id"], name: "index_events_on_external_id", unique: true
    t.index ["starts_at"], name: "index_events_on_starts_at"
  end

  create_table "vote_counts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "downvotes", default: 0, null: false
    t.bigint "event_id", null: false
    t.datetime "updated_at", null: false
    t.integer "upvotes", default: 0, null: false
    t.index ["event_id"], name: "index_vote_counts_on_event_id", unique: true
  end

  add_foreign_key "applied_vote_facts", "events"
  add_foreign_key "event_store_events_in_streams", "event_store_events", column: "event_id", primary_key: "event_id"
  add_foreign_key "vote_counts", "events"
end
