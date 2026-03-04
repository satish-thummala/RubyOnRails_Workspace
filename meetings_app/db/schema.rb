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

ActiveRecord::Schema[7.1].define(version: 2024_01_02_000000) do
  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "zoom_meetings", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "topic", null: false
    t.text "agenda"
    t.integer "meeting_type", default: 2
    t.datetime "start_time"
    t.integer "duration", default: 60
    t.string "timezone", default: "UTC"
    t.string "password"
    t.boolean "waiting_room", default: false
    t.boolean "join_before_host", default: false
    t.boolean "mute_upon_entry", default: true
    t.boolean "require_password", default: false
    t.string "host_video", default: "on"
    t.string "participant_video", default: "on"
    t.string "audio", default: "both"
    t.boolean "auto_recording", default: false
    t.string "recording_type", default: "none"
    t.boolean "allow_multiple_devices", default: false
    t.boolean "approval_type", default: false
    t.boolean "registrants_email_notification", default: true
    t.string "recurrence_type"
    t.integer "repeat_interval", default: 1
    t.string "weekly_days"
    t.date "end_date_time"
    t.integer "end_times", default: 1
    t.string "zoom_meeting_id"
    t.string "zoom_uuid"
    t.string "join_url"
    t.string "start_url"
    t.string "status", default: "scheduled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_zoom_meetings_on_status"
    t.index ["user_id"], name: "index_zoom_meetings_on_user_id"
    t.index ["zoom_meeting_id"], name: "index_zoom_meetings_on_zoom_meeting_id"
  end

  add_foreign_key "zoom_meetings", "users"
end
