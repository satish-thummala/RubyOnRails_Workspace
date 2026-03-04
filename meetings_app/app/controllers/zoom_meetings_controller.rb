class ZoomMeetingsController < ApplicationController
  before_action :require_login
  before_action :set_meeting, only: [:show, :edit, :update, :destroy, :cancel]

  def index
    @upcoming_meetings = current_user.zoom_meetings.upcoming
    @past_meetings     = current_user.zoom_meetings.past
    @total             = current_user.zoom_meetings.count
  end

  def show
  end

  def new
    @meeting = ZoomMeeting.new(
      meeting_type: 2,
      duration: 60,
      timezone: "Eastern Time (US & Canada)",
      start_time: Time.current.beginning_of_hour + 1.hour,
      host_video: "on",
      participant_video: "on",
      audio: "both",
      recording_type: "none",
      mute_upon_entry: true,
      waiting_room: false,
      join_before_host: false
    )
  end

  def create
    @meeting = current_user.zoom_meetings.build(meeting_params)

    if @meeting.valid?
      # Try to create meeting on Zoom first
      zoom_result = create_zoom_meeting(@meeting)

      if zoom_result[:success]
        # Save with Zoom data populated
        if @meeting.save
          flash[:notice] = "✅ Meeting \"#{@meeting.topic}\" scheduled and created on Zoom!"
          redirect_to zoom_meetings_path
        else
          flash[:alert] = "Meeting saved locally but had an issue: #{@meeting.errors.full_messages.join(', ')}"
          redirect_to zoom_meetings_path
        end
      else
        # Zoom API failed — still save locally, show warning
        @meeting.save
        flash[:alert] = "⚠️ Meeting saved locally but Zoom API failed: #{zoom_result[:error]}. Please check your Zoom credentials in config."
        redirect_to zoom_meetings_path
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @meeting.update(meeting_params)
      # Sync update to Zoom if meeting has a Zoom ID
      if @meeting.zoom_meeting_id.present?
        sync_result = update_zoom_meeting(@meeting)
        if sync_result[:success]
          flash[:notice] = "✅ Meeting updated and synced to Zoom!"
        else
          flash[:notice] = "✅ Meeting updated locally. ⚠️ Zoom sync failed: #{sync_result[:error]}"
        end
      else
        flash[:notice] = "✅ Meeting updated successfully!"
      end
      redirect_to zoom_meetings_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Delete from Zoom first if linked
    if @meeting.zoom_meeting_id.present?
      delete_zoom_meeting(@meeting.zoom_meeting_id)
    end
    @meeting.destroy
    flash[:notice] = "🗑️ Meeting deleted."
    redirect_to zoom_meetings_path
  end

  def cancel
    @meeting.update(status: "cancelled")
    flash[:notice] = "Meeting cancelled."
    redirect_to zoom_meetings_path
  end

  private

  # ─── ZOOM API CALLS ──────────────────────────────────────────────────────────

  def create_zoom_meeting(meeting)
    service = ZoomApiService.new
    response = service.create_meeting(meeting)

    # Populate meeting with Zoom response data
    meeting.zoom_meeting_id = response["id"].to_s
    meeting.zoom_uuid       = response["uuid"]
    meeting.join_url        = response["join_url"]
    meeting.start_url       = response["start_url"]
    meeting.status          = "scheduled"

    { success: true }
  rescue ZoomApiService::ZoomApiError => e
    Rails.logger.error "Zoom API Error (create): #{e.message}"
    { success: false, error: e.message }
  rescue StandardError => e
    Rails.logger.error "Unexpected Zoom error (create): #{e.message}"
    { success: false, error: "Unexpected error: #{e.message}" }
  end

  def update_zoom_meeting(meeting)
    service = ZoomApiService.new
    service.update_meeting(meeting.zoom_meeting_id, meeting)
    { success: true }
  rescue ZoomApiService::ZoomApiError => e
    Rails.logger.error "Zoom API Error (update): #{e.message}"
    { success: false, error: e.message }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def delete_zoom_meeting(zoom_id)
    service = ZoomApiService.new
    service.delete_meeting(zoom_id)
  rescue ZoomApiService::ZoomApiError => e
    Rails.logger.error "Zoom API Error (delete): #{e.message}"
  end

  # ─── HELPERS ─────────────────────────────────────────────────────────────────

  def set_meeting
    @meeting = current_user.zoom_meetings.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Meeting not found."
    redirect_to zoom_meetings_path
  end

  def meeting_params
    params.require(:zoom_meeting).permit(
      :topic, :agenda, :meeting_type, :start_time, :duration, :timezone,
      :password, :waiting_room, :join_before_host, :mute_upon_entry, :require_password,
      :host_video, :participant_video, :audio,
      :auto_recording, :recording_type, :allow_multiple_devices,
      :approval_type, :registrants_email_notification,
      :recurrence_type, :repeat_interval, :weekly_days, :end_date_time, :end_times,
      :zoom_meeting_id, :join_url, :start_url, :status
    )
  end
end
