# app/services/zoom_api_service.rb
#
# Handles all communication with the Zoom API v2
# Uses Server-to-Server OAuth (recommended over JWT which is deprecated)
#
# Setup:
#   1. Go to https://marketplace.zoom.us/develop/create
#   2. Create a "Server-to-Server OAuth" app
#   3. Add scopes: meeting:write:admin, meeting:read:admin
#   4. Copy Account ID, Client ID, Client Secret into your .env or credentials

require 'net/http'
require 'uri'
require 'json'
require 'base64'

class ZoomApiService
  ZOOM_API_BASE = "https://api.zoom.us/v2".freeze
  ZOOM_OAUTH_URL = "https://zoom.us/oauth/token".freeze

  class ZoomApiError < StandardError
    attr_reader :code, :response_body
    def initialize(msg, code: nil, body: nil)
      super(msg)
      @code = code
      @response_body = body
    end
  end

  def initialize
    @account_id    = "4d8-Xu96R6qg3zL5UhbvmQ"
    @client_id     = "jbiUTb1URmKe9B6Ky0493A"
    @client_secret = "DBXA6GqwkegoJt3Lz1TSbalRDVxb1Xnt"
    raise ZoomApiError, "Zoom credentials not configured. Set ZOOM_ACCOUNT_ID, ZOOM_CLIENT_ID, ZOOM_CLIENT_SECRET." if missing_credentials?
  end

  # ─── MEETINGS ────────────────────────────────────────────────────────────────

  # Create a Zoom meeting for a given user_id (use 'me' for the authenticated user)
  def create_meeting(zoom_meeting, user_id: "me")
    post("/users/#{user_id}/meetings", build_meeting_payload(zoom_meeting))
  end

  # Update an existing Zoom meeting
  def update_meeting(zoom_meeting_id, zoom_meeting)
    patch("/meetings/#{zoom_meeting_id}", build_meeting_payload(zoom_meeting))
  end

  # Delete a Zoom meeting
  def delete_meeting(zoom_meeting_id)
    delete("/meetings/#{zoom_meeting_id}")
  end

  # Get meeting details
  def get_meeting(zoom_meeting_id)
    get("/meetings/#{zoom_meeting_id}")
  end

  # List meetings for a user
  def list_meetings(user_id: "me", type: "scheduled")
    get("/users/#{user_id}/meetings", { type: type })
  end

  private

  # ─── PAYLOAD BUILDER ─────────────────────────────────────────────────────────

  def build_meeting_payload(meeting)
    payload = {
      topic:      meeting.topic,
      type:       meeting.meeting_type,
      duration:   meeting.duration,
      timezone:   meeting.timezone,
      agenda:     meeting.agenda.presence || "",
      settings: {
        host_video:          meeting.host_video == "on",
        participant_video:   meeting.participant_video == "on",
        join_before_host:    meeting.join_before_host,
        mute_upon_entry:     meeting.mute_upon_entry,
        waiting_room:        meeting.waiting_room,
        audio:               meeting.audio,
        auto_recording:      meeting.recording_type == "none" ? "none" : meeting.recording_type,
        approval_type:       meeting.approval_type ? 1 : 0,
        registrants_email_notification: meeting.registrants_email_notification,
        allow_multiple_devices: meeting.allow_multiple_devices
      }
    }

    # Add start_time for scheduled/recurring fixed meetings
    if [2, 8].include?(meeting.meeting_type) && meeting.start_time.present?
      payload[:start_time] = meeting.start_time.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    end

    # Add passcode if present
    if meeting.password.present?
      payload[:password] = meeting.password
      payload[:settings][:password] = meeting.password
    end

    # Add recurrence for recurring meetings
    if [3, 8].include?(meeting.meeting_type) && meeting.recurrence_type.present?
      payload[:recurrence] = build_recurrence_payload(meeting)
    end

    payload
  end

  def build_recurrence_payload(meeting)
    recurrence = {
      type:            recurrence_type_int(meeting.recurrence_type),
      repeat_interval: meeting.repeat_interval || 1
    }

    if meeting.recurrence_type == "weekly" && meeting.weekly_days.present?
      recurrence[:weekly_days] = meeting.weekly_days
    end

    if meeting.end_date_time.present?
      recurrence[:end_date_time] = meeting.end_date_time.to_time.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    elsif meeting.end_times.present?
      recurrence[:end_times] = meeting.end_times
    end

    recurrence
  end

  def recurrence_type_int(type)
    { "daily" => 1, "weekly" => 2, "monthly" => 3 }[type] || 1
  end

  # ─── HTTP METHODS ─────────────────────────────────────────────────────────────

  def get(path, params = {})
    uri = URI("#{ZOOM_API_BASE}#{path}")
    uri.query = URI.encode_www_form(params) if params.any?

    request = Net::HTTP::Get.new(uri)
    execute(request, uri)
  end

  def post(path, body)
    uri = URI("#{ZOOM_API_BASE}#{path}")
    request = Net::HTTP::Post.new(uri)
    request.body = body.to_json
    execute(request, uri)
  end

  def patch(path, body)
    uri = URI("#{ZOOM_API_BASE}#{path}")
    request = Net::HTTP::Patch.new(uri)
    request.body = body.to_json
    execute(request, uri)
  end

  def delete(path)
    uri = URI("#{ZOOM_API_BASE}#{path}")
    request = Net::HTTP::Delete.new(uri)
    execute(request, uri)
  end

  def execute(request, uri)
    request["Authorization"] = "Bearer #{access_token}"
    request["Content-Type"]  = "application/json"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    handle_response(response)
  end

  # ─── AUTH ─────────────────────────────────────────────────────────────────────

  def access_token
    # Cache token in memory for its lifetime (typically 1 hour)
    if @token_expires_at.nil? || Time.current >= @token_expires_at
      fetch_access_token
    end
    @access_token
  end

  def fetch_access_token
    uri = URI(ZOOM_OAUTH_URL)
    uri.query = URI.encode_www_form(grant_type: "account_credentials", account_id: @account_id)

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Basic #{Base64.strict_encode64("#{@client_id}:#{@client_secret}")}"
    request["Content-Type"]  = "application/x-www-form-urlencoded"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |h| h.request(request) }
    data = JSON.parse(response.body)

    raise ZoomApiError.new("Failed to get Zoom access token: #{data['reason'] || data['message']}", body: data) unless data["access_token"]

    @access_token    = data["access_token"]
    @token_expires_at = Time.current + (data["expires_in"].to_i - 60).seconds
    @access_token
  end

  # ─── RESPONSE HANDLING ────────────────────────────────────────────────────────

  def handle_response(response)
    body = response.body.present? ? JSON.parse(response.body) : {}

    case response.code.to_i
    when 200, 201, 204
      body
    when 400
      raise ZoomApiError.new("Bad request: #{body['message']}", code: 400, body: body)
    when 401
      raise ZoomApiError.new("Unauthorized: Check your Zoom credentials", code: 401, body: body)
    when 404
      raise ZoomApiError.new("Zoom meeting not found", code: 404, body: body)
    when 429
      raise ZoomApiError.new("Zoom API rate limit exceeded. Try again later.", code: 429, body: body)
    else
      raise ZoomApiError.new("Zoom API error (#{response.code}): #{body['message']}", code: response.code.to_i, body: body)
    end
  rescue JSON::ParserError
    {}
  end

  def missing_credentials?
    [@account_id, @client_id, @client_secret].any?(&:blank?)
  end
end
