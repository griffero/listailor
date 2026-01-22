module Api
  module V1
    class EmailMessagesController < BaseController
      def create
        application = Application.find(params[:application_id])

        # Upsert by provider_message_id if provided
        if params[:provider_message_id].present?
          email = EmailMessage.find_by(provider_message_id: params[:provider_message_id])
        end

        email ||= application.email_messages.new

        email.assign_attributes(
          application: application,
          direction: params[:direction],
          status: params[:status] || (params[:direction] == "inbound" ? "received" : "sent"),
          from_address: params[:from_address],
          to_address: params[:to_address],
          subject: params[:subject],
          body_html: params[:body_html],
          provider_message_id: params[:provider_message_id],
          sent_at: params[:sent_at],
          received_at: params[:received_at]
        )

        if email.save
          render json: {
            id: email.id,
            application_id: email.application_id,
            direction: email.direction,
            status: email.status,
            from_address: email.from_address,
            to_address: email.to_address,
            subject: email.subject,
            provider_message_id: email.provider_message_id
          }, status: email.previously_new_record? ? :created : :ok
        else
          render_validation_errors(email)
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Application not found" }, status: :not_found
      end
    end
  end
end
