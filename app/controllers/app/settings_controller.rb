module App
  class SettingsController < BaseController
    def index
      render inertia: "App/Settings/Index", props: {
        settings: {
          outboundWebhookUrl: Setting.get("outbound_webhook_url") || "",
          n8nSendEmailWebhookUrl: Setting.get("n8n_send_email_webhook_url") || "",
          embedAllowedOrigins: Setting.get("embed_allowed_origins") || "",
          departments: Setting.departments,
          locations: Setting.locations
        },
        envSettings: {
          outboundWebhookUrl: ENV["OUTBOUND_WEBHOOK_URL"],
          n8nSendEmailWebhookUrl: ENV["N8N_SEND_EMAIL_WEBHOOK_URL"],
          embedAllowedOrigins: ENV["EMBED_ALLOWED_ORIGINS"]
        },
        globalQuestions: GlobalQuestion.ordered.map { |q| serialize_global_question(q) }
      }
    end

    def update
      Setting.set("outbound_webhook_url", params[:outbound_webhook_url]) if params[:outbound_webhook_url]
      Setting.set("n8n_send_email_webhook_url", params[:n8n_send_email_webhook_url]) if params[:n8n_send_email_webhook_url]
      Setting.set("embed_allowed_origins", params[:embed_allowed_origins]) if params[:embed_allowed_origins]

      if params[:departments].present?
        departments = params[:departments].is_a?(String) ? JSON.parse(params[:departments]) : params[:departments]
        Setting.departments = departments
      end

      if params[:locations].present?
        locations = params[:locations].is_a?(String) ? JSON.parse(params[:locations]) : params[:locations]
        Setting.locations = locations
      end

      redirect_to app_settings_path, notice: "Settings saved"
    end

    private

    def serialize_global_question(question)
      {
        id: question.id,
        label: question.label,
        kind: question.kind,
        required: question.required,
        position: question.position,
        options: question.select_options
      }
    end
  end
end
