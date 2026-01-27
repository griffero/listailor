module App
  class ApplicationEmailsController < BaseController
    before_action :set_application
    before_action :require_write_permission!

    def new
      @templates = EmailTemplate.ordered

      render inertia: "App/Applications/ComposeEmail", props: {
        application: serialize_application(@application),
        templates: @templates.map { |t| serialize_template(t) }
      }
    end

    def create
      template = params[:template_id].present? ? EmailTemplate.find(params[:template_id]) : nil
      context = TemplateRenderer.context_for_application(@application)

      subject = template ? template.render_subject(context) : params[:subject]
      body = template ? template.render_body(context) : params[:body]

      # Allow overrides
      subject = params[:subject] if params[:subject].present?
      body = params[:body] if params[:body].present?

      from_address = ENV.fetch("SMTP_FROM_ADDRESS", "noreply@listailor.local")

      @email = @application.email_messages.create!(
        direction: "outbound",
        status: "queued",
        from_address: from_address,
        to_address: @application.candidate.email,
        subject: subject,
        body_html: body
      )

      # Enqueue sending
      SendEmailJob.perform_later(@email.id)

      redirect_to app_application_path(@application), notice: "Email queued for sending"
    end

    private

    def set_application
      @application = Application.find(params[:application_id])
    end

    def serialize_application(app)
      {
        id: app.id,
        candidate: {
          name: app.candidate.full_name,
          email: app.candidate.email
        },
        job: {
          title: app.job_posting.title
        },
        stage: app.current_stage ? { name: app.current_stage.name } : nil
      }
    end

    def serialize_template(template)
      {
        id: template.id,
        name: template.name,
        subject: template.subject,
        body: template.body
      }
    end
  end
end
