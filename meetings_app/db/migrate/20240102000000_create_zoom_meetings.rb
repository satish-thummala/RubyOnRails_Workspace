class CreateZoomMeetings < ActiveRecord::Migration[7.1]
  def change
    create_table :zoom_meetings do |t|
      t.references :user, null: false, foreign_key: true

      # Basic info
      t.string  :topic,            null: false
      t.text    :agenda
      t.integer :meeting_type,     default: 2   # 1=instant, 2=scheduled, 3=recurring no fixed, 8=recurring fixed

      # Schedule
      t.datetime :start_time
      t.integer  :duration,        default: 60  # minutes
      t.string   :timezone,        default: "UTC"

      # Security
      t.string  :password
      t.boolean :waiting_room,     default: false
      t.boolean :join_before_host, default: false
      t.boolean :mute_upon_entry,  default: true
      t.boolean :require_password, default: false

      # Video & Audio
      t.string  :host_video,       default: "on"   # on/off
      t.string  :participant_video, default: "on"
      t.string  :audio,            default: "both" # voip/telephony/both

      # Meeting options
      t.boolean :auto_recording,   default: false
      t.string  :recording_type,   default: "none" # none/local/cloud
      t.boolean :allow_multiple_devices, default: false
      t.boolean :approval_type,    default: false  # false=auto, true=manual
      t.boolean :registrants_email_notification, default: true

      # Recurrence (for recurring meetings)
      t.string  :recurrence_type   # daily/weekly/monthly
      t.integer :repeat_interval,  default: 1
      t.string  :weekly_days       # comma separated: 1,2,3 (Sun=1)
      t.date    :end_date_time
      t.integer :end_times,        default: 1

      # Zoom API response fields
      t.string  :zoom_meeting_id
      t.string  :zoom_uuid
      t.string  :join_url
      t.string  :start_url
      t.string  :status,           default: "scheduled"  # scheduled/started/ended/cancelled

      t.timestamps
    end

    add_index :zoom_meetings, :zoom_meeting_id
    add_index :zoom_meetings, :status
  end
end
