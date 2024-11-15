class RecurringMeetingsController < ApplicationController
  include Layout
  include OpTurbo::ComponentStream
  include OpTurbo::FlashStreamHelper
  include OpTurbo::DialogStreamHelper

  before_action :find_meeting, only: %i[show update details_dialog]
  before_action :find_optional_project, only: %i[index show new create update details_dialog]
  before_action :authorize_global, only: %i[index new create]
  before_action :authorize, except: %i[index new create]

  before_action :convert_params, only: %i[create update]

  menu_item :meetings

  def index
    @recurring_meetings =
      if @project
        RecurringMeeting.visible.where(project_id: @project.id)
      else
        RecurringMeeting.visible
      end
  end

  def new
    @recurring_meeting = RecurringMeeting.new(project: @project)
  end

  def show
    @meetings = collect_meetings

    respond_to do |format|
      format.html
    end
  end

  def collect_meetings
    meetings = []
    @recurring_meeting.meetings.each do |meeting|
      meetings << meeting unless meeting.template == true
    end

    template_attributes = @recurring_meeting.meetings.where(template: true).first.attributes
    @recurring_meeting
      .schedule
      .occurrences(@recurring_meeting.end_date)
      .each do |date|
      exists = meetings.find { |m| m["start_time"] == date }
      unless exists
        attributes = template_attributes.dup
        attributes["start_time"] = date
        attributes["state"] = "scheduled"
        attributes["template"] = false
        meetings << Meeting.new(**attributes)
        # @recurring_meeting.meetings.build(**attributes)
      end
    end

    # SELECT COALESCE(meetings.start_time, meetings.recurring_date) start_time_test FROM
    # (SELECT * FROM (VALUES (to_timestamp('2024-10-06 11:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'ABC'),
    # (to_timestamp('2024-10-06 11:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'ABC')) AS t (recurring_date, recurring_title)
    # FULL JOIN meetings ON meetings.start_time = t.recurring_date) meetings ORDER BY start_time_test;

    meetings
  end

  def details_dialog
    respond_with_dialog Meetings::Index::DialogComponent.new(
      meeting: @recurring_meeting,
      project: @recurring_meeting.project
    )
  end

  def create
    call = ::RecurringMeetings::CreateService
      .new(user: current_user)
      .call(@converted_params)

    if call.success?
      redirect_to status: :see_other, action: :show, id: call.result
    else
      respond_to do |format|
        format.turbo_stream do
          update_via_turbo_stream(
            component: Meetings::Index::FormComponent.new(
              meeting: call.result,
              project: @project,
              copy_from: @copy_from
            ),
            status: :bad_request
          )

          respond_with_turbo_streams
        end
      end
    end
  end

  def update
    call = ::RecurringMeetings::UpdateService
      .new(model: @recurring_meeting, user: current_user)
      .call(@converted_params)

    if call.success?
      redirect_back(fallback_location: recurring_meeting_path(call.result), status: :see_other, turbo: false)
    else
      respond_to do |format|
        format.turbo_stream do
          update_via_turbo_stream(
            component: Meetings::Index::FormComponent.new(
              meeting: call.result,
              project: @project
            ),
            status: :bad_request
          )

          respond_with_turbo_streams
        end
      end
    end
  end

  private

  def find_optional_project
    @project = Project.find(params[:project_id]) if params[:project_id].present?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_meeting
    @recurring_meeting = RecurringMeeting.visible.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def convert_params
    # We do some preprocessing of `meeting_params` that we will store in this
    # instance variable.
    @converted_params = recurring_meeting_params.to_h

    @converted_params[:project] = @project
    @converted_params[:duration] = @converted_params[:duration].to_hours if @converted_params[:duration].present?
  end

  def recurring_meeting_params
    params
      .require(:meeting)
      .permit(:title, :location, :start_time_hour, :duration, :start_date,
              :frequency, :end_after, :end_date, :iterations)
  end

  def find_copy_from_meeting
    copied_from_meeting_id = params[:copied_from_meeting_id] || params[:meeting][:copied_from_meeting_id]
    return unless copied_from_meeting_id

    @copy_from = Meeting.visible.find(copied_from_meeting_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def structured_meeting_params
    if params[:structured_meeting].present?
      params
        .require(:structured_meeting)
    end
  end
end
