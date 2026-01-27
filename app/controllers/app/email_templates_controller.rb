module App
  class EmailTemplatesController < BaseController
    before_action :set_template, only: [:show, :edit, :update, :destroy]
    before_action :require_write_permission!, only: [:new, :create, :edit, :update, :destroy]

    def index
      @templates = EmailTemplate.ordered

      render inertia: "App/EmailTemplates/Index", props: {
        templates: @templates.map { |t| serialize_template(t) },
        variables: EmailTemplate::VARIABLES
      }
    end

    def show
      render inertia: "App/EmailTemplates/Show", props: {
        template: serialize_template(@template),
        variables: EmailTemplate::VARIABLES
      }
    end

    def new
      render inertia: "App/EmailTemplates/Form", props: {
        template: nil,
        variables: EmailTemplate::VARIABLES
      }
    end

    def create
      @template = EmailTemplate.new(template_params)
      @template.created_by_user = current_user

      if @template.save
        redirect_to app_email_templates_path, notice: "Template created"
      else
        redirect_to new_app_email_template_path, alert: @template.errors.full_messages.join(", ")
      end
    end

    def edit
      render inertia: "App/EmailTemplates/Form", props: {
        template: serialize_template(@template),
        variables: EmailTemplate::VARIABLES
      }
    end

    def update
      if @template.update(template_params)
        redirect_to app_email_templates_path, notice: "Template updated"
      else
        redirect_to edit_app_email_template_path(@template), alert: @template.errors.full_messages.join(", ")
      end
    end

    def destroy
      @template.destroy
      redirect_to app_email_templates_path, notice: "Template deleted"
    end

    private

    def set_template
      @template = EmailTemplate.find(params[:id])
    end

    def template_params
      params.require(:email_template).permit(:name, :subject, :body)
    end

    def serialize_template(template)
      {
        id: template.id,
        name: template.name,
        subject: template.subject,
        body: template.body,
        createdAt: template.created_at.iso8601
      }
    end
  end
end
