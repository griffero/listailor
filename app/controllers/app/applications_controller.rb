module App
  class ApplicationsController < BaseController
    before_action :set_application, only: [:show, :move_stage]

    def index
      @applications = Application.includes(:candidate, :job_posting, :current_stage)
                                  .recent

      # Filters
      @applications = @applications.for_job(params[:job_id]) if params[:job_id].present?
      @applications = @applications.for_stage(params[:stage_id]) if params[:stage_id].present?
      @applications = @applications.search(params[:q]) if params[:q].present?

      @applications = @applications.page(params[:page]).per(25) if @applications.respond_to?(:page)

      render inertia: "App/Applications/Index", props: {
        applications: @applications.limit(100).map { |app| serialize_application(app) },
        jobs: JobPosting.ordered.map { |job| { id: job.id, title: job.title } },
        stages: PipelineStage.ordered.map { |stage| { id: stage.id, name: stage.name } },
        filters: {
          jobId: params[:job_id],
          stageId: params[:stage_id],
          query: params[:q]
        }
      }
    end

    def show
      render inertia: "App/Applications/Show", props: {
        application: serialize_application_full(@application),
        stages: PipelineStage.ordered.map { |stage| serialize_stage(stage) },
        emailTemplates: EmailTemplate.ordered.map { |t| { id: t.id, name: t.name } },
        timeline: @application.timeline_items
      }
    end

    def new
      render inertia: "App/Applications/Form", props: {
        jobs: JobPosting.published.ordered.map { |job| { id: job.id, title: job.title } }
      }
    end

    def create
      # Manual application creation
      candidate = Candidate.find_or_create_by_email(
        email: application_params[:email],
        first_name: application_params[:first_name],
        last_name: application_params[:last_name],
        phone: application_params[:phone],
        linkedin_url: application_params[:linkedin_url]
      )

      @application = Application.new(
        job_posting_id: application_params[:job_posting_id],
        candidate: candidate,
        source: application_params[:source] || "manual"
      )

      if application_params[:cv].present?
        @application.cv.attach(application_params[:cv])
      end

      if @application.save
        # Add note if provided
        if application_params[:notes].present?
          @application.events.create!(
            event_type: "note",
            message: application_params[:notes],
            occurred_at: Time.current,
            created_by_user: current_user
          )
        end

        redirect_to app_application_path(@application), notice: "Application created successfully"
      else
        redirect_to new_app_application_path, alert: @application.errors.full_messages.join(", ")
      end
    rescue ActiveRecord::RecordInvalid => e
      redirect_to new_app_application_path, alert: e.message
    end

    def move_stage
      stage = PipelineStage.find(params[:stage_id])
      @application.move_to_stage!(stage, user: current_user)
      
      respond_to do |format|
        format.html { redirect_to app_application_path(@application), notice: "Stage updated" }
        format.json { head :ok }
      end
    end

    private

    def set_application
      @application = Application.includes(:candidate, :job_posting, :current_stage, :application_answers, :email_messages, :interview_events, :events).find(params[:id])
    end

    def application_params
      params.require(:application).permit(
        :job_posting_id, :first_name, :last_name, :email, :phone, :linkedin_url, :source, :notes, :cv
      )
    end

    def serialize_application(app)
      {
        id: app.id,
        candidate: {
          id: app.candidate.id,
          name: app.candidate.full_name,
          email: app.candidate.email,
          phone: app.candidate.phone,
          linkedinUrl: app.candidate.linkedin_url
        },
        job: {
          id: app.job_posting.id,
          title: app.job_posting.title
        },
        stage: app.current_stage ? { id: app.current_stage.id, name: app.current_stage.name, kind: app.current_stage.kind } : nil,
        source: app.source,
        createdAt: app.created_at.iso8601
      }
    end

    def serialize_application_full(app)
      serialize_application(app).merge(
        utmSource: app.utm_source,
        utmMedium: app.utm_medium,
        utmCampaign: app.utm_campaign,
        cvUrl: app.cv.attached? ? rails_blob_path(app.cv) : nil,
        answers: app.application_answers.ordered.map do |answer|
          {
            question: answer.question_label,
            kind: answer.question_kind,
            value: answer.value
          }
        end,
        emails: app.email_messages.order(Arel.sql("COALESCE(sent_at, received_at, created_at) ASC"))
          .map { |email| serialize_email(email) },
        interviews: app.interview_events.ordered.map { |interview| serialize_interview(interview) }
      )
    end

    def serialize_stage(stage)
      {
        id: stage.id,
        name: stage.name,
        kind: stage.kind,
        position: stage.position
      }
    end

    def serialize_email(email)
      {
        id: email.id,
        direction: email.direction,
        status: email.status,
        from: email.from_address,
        to: email.to_address,
        subject: email.subject,
        body: email.body_html,
        sentAt: email.sent_at&.iso8601,
        receivedAt: email.received_at&.iso8601
      }
    end

    def serialize_interview(interview)
      {
        id: interview.id,
        title: interview.title,
        scheduledAt: interview.scheduled_at.iso8601,
        durationMinutes: interview.duration_minutes,
        meetingUrl: interview.meeting_url,
        participants: interview.participants_list
      }
    end
  end
end
