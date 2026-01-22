module Api
  module V1
    class ApplicationEventsController < BaseController
      def create
        application = Application.find(params[:application_id])

        event = application.events.build(
          event_type: params[:event_type] || "external_event",
          message: params[:message],
          payload: params[:payload] || {},
          occurred_at: params[:occurred_at] || Time.current
        )

        if event.save
          render json: {
            id: event.id,
            application_id: event.application_id,
            event_type: event.event_type,
            message: event.message,
            occurred_at: event.occurred_at.iso8601
          }, status: :created
        else
          render_validation_errors(event)
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Application not found" }, status: :not_found
      end
    end
  end
end
