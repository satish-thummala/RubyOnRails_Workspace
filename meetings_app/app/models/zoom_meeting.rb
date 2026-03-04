class ZoomMeeting < ApplicationRecord
  belongs_to :user

  MEETING_TYPES = {
    "Instant Meeting"              => 1,
    "Scheduled Meeting"            => 2,
    "Recurring (No Fixed Time)"    => 3,
    "Recurring (Fixed Time)"       => 8
  }.freeze

  TIMEZONES = ActiveSupport::TimeZone.all.map { |tz| tz.name }.freeze

  RECURRENCE_TYPES = %w[daily weekly monthly].freeze

  AUDIO_OPTIONS = {
    "Both (VoIP & Telephony)" => "both",
    "VoIP Only"               => "voip",
    "Telephony Only"          => "telephony"
  }.freeze

  RECORDING_TYPES = {
    "No Recording" => "none",
    "Local"        => "local",
    "Cloud"        => "cloud"
  }.freeze

  STATUSES = %w[scheduled started ended cancelled].freeze

  validates :topic, presence: true, length: { maximum: 200 }
  validates :duration, numericality: { greater_than: 0, less_than_or_equal_to: 1440 }
  validates :start_time, presence: true, if: -> { [2, 8].include?(meeting_type) }
  validates :password, length: { maximum: 10 }, allow_blank: true
  validates :recurrence_type, presence: true, if: -> { [3, 8].include?(meeting_type) }

  scope :upcoming,   -> { where("start_time > ?", Time.current).order(:start_time) }
  scope :past,       -> { where("start_time <= ?", Time.current).order(start_time: :desc) }
  scope :scheduled,  -> { where(status: "scheduled") }
  scope :by_user,    ->(user) { where(user: user) }

  def scheduled?   = status == "scheduled"
  def started?     = status == "started"
  def ended?       = status == "ended"
  def cancelled?   = status == "cancelled"
  def recurring?   = [3, 8].include?(meeting_type)
  def instant?     = meeting_type == 1

  def type_name
    MEETING_TYPES.key(meeting_type)
  end

  def duration_formatted
    h = duration / 60
    m = duration % 60
    parts = []
    parts << "#{h}h" if h > 0
    parts << "#{m}m" if m > 0
    parts.join(" ")
  end

  def status_badge_color
    case status
    when "scheduled"  then "#667eea"
    when "started"    then "#10b981"
    when "ended"      then "#6b7280"
    when "cancelled"  then "#ef4444"
    end
  end
end
