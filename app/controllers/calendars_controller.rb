require 'open-uri'

class CalendarsController < ApplicationController
  before_action :set_calendar, only: %i[ show edit update destroy ]

  # GET /calendars or /calendars.json
  def index
    url = 'https://churchofjesuschrist.org/church-calendar/services/lucrs/ical/group/b03afe3544134ca59a839688d454fb2b'
    
    begin
      raw_file = URI.parse(url).read
      calendar = Calendar.create_or_find_by(url: url)
      calendar.update(raw: raw_file)
    rescue OpenURI::HTTPError => e
      logger.debug e
      raw_file = Calendar.find_by(url: url).raw
    end

    ical = Icalendar::Calendar.parse(raw_file).first

    events_by_month = ical.events.reverse.inject({}) do |by_month, event|
      month = DateTime::MONTHNAMES[event.dtstart.to_datetime.month]
      by_month[month] ? by_month[month] << event : by_month[month] = [event]
      by_month
    end

    @icalendar = OpenStruct.new(
      events: ical.events,
      events_by_month: events_by_month
    )
  end

  # GET /calendars/1 or /calendars/1.json
  def show
  end

  # GET /calendars/new
  def new
    @calendar = Calendar.new
  end

  # GET /calendars/1/edit
  def edit
  end

  # POST /calendars or /calendars.json
  def create
    @calendar = Calendar.new(calendar_params)

    respond_to do |format|
      if @calendar.save
        format.html { redirect_to @calendar, notice: "Calendar was successfully created." }
        format.json { render :show, status: :created, location: @calendar }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @calendar.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /calendars/1 or /calendars/1.json
  def update
    respond_to do |format|
      if @calendar.update(calendar_params)
        format.html { redirect_to @calendar, notice: "Calendar was successfully updated." }
        format.json { render :show, status: :ok, location: @calendar }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @calendar.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /calendars/1 or /calendars/1.json
  def destroy
    @calendar.destroy
    respond_to do |format|
      format.html { redirect_to calendars_url, notice: "Calendar was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_calendar
      @calendar = Calendar.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def calendar_params
      params.fetch(:calendar, {})
    end
end
