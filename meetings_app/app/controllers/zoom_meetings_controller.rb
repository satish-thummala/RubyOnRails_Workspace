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

    if @meeting.save
      flash[:notice] = "✅ Meeting \"#{@meeting.topic}\" has been scheduled!"
      redirect_to zoom_meetings_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @meeting.update(meeting_params)
      flash[:notice] = "✅ Meeting updated successfully!"
      redirect_to zoom_meetings_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
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
