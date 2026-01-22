module Api
  module V1
    class InterviewsController < BaseController
      def create
        application = Application.find(params[:application_id])

        interview = application.interview_events.build(
          title: params[:title],
          scheduled_at: params[:scheduled_at],
          duration_minutes: params[:duration_minutes] || 60,
          meeting_url: params[:meeting_url],
          participants: params[:participants] || []
        )

        if interview.save
          # Create a timeline event for the interview
          application.events.create!(
            event_type: "interview_scheduled",
            message: "Interview scheduled: #{interview.title}",
            payload: {
              interview_id: interview.id,
              scheduled_at: interview.scheduled_at.iso8601,
              meeting_url: interview.meeting_url
            },
            occurred_at: Time.current
          )

          render json: serialize_interview(interview), status: :created
        else
          render_validation_errors(interview)
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Application not found" }, status: :not_found
      end

      def update
        interview = InterviewEvent.find(params[:id])

        interview.assign_attributes(interview_params)

        if interview.save
          render json: serialize_interview(interview)
        else
          render_validation_errors(interview)
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Interview not found" }, status: :not_found
      end

      private

      def interview_params
        params.permit(:title, :scheduled_at, :duration_minutes, :meeting_url, participants: [])
      end

      def serialize_interview(interview)
        {
          id: interview.id,
          application_id: interview.application_id,
          title: interview.title,
          scheduled_at: interview.scheduled_at.iso8601,
          duration_minutes: interview.duration_minutes,
          meeting_url: interview.meeting_url,
          participants: interview.participants_list
        }
      end
    end
  end
end
