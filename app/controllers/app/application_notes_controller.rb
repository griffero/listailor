module App
  class ApplicationNotesController < BaseController
    before_action :set_application
    before_action :require_write_permission!

    def create
      @event = @application.events.build(
        event_type: "note",
        message: params[:message],
        occurred_at: Time.current,
        created_by_user: current_user
      )

      if @event.save
        redirect_to app_application_path(@application), notice: "Note added"
      else
        redirect_to app_application_path(@application), alert: "Failed to add note"
      end
    end

    private

    def set_application
      @application = Application.find(params[:application_id])
    end
  end
end
