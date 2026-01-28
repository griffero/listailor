module App
  class ApplicationsController < BaseController
    before_action :set_application, only: [:show, :move_stage, :toggle_stage_completion, :re_evaluate]
    before_action :require_write_permission!, only: [:new, :create, :move_stage, :toggle_stage_completion, :re_evaluate]

    def index
      @applications = Application.includes(:candidate, :job_posting, :current_stage)
                                  .recent

      # Filters
      @applications = @applications.for_job(params[:job_id]) if params[:job_id].present?
      @applications = @applications.for_canonical_stage(params[:canonical_stage]) if params[:canonical_stage].present?
      @applications = @applications.search(params[:q]) if params[:q].present?
      @applications = filter_by_insights(@applications, params[:insights]) if params[:insights].present?

      @applications = @applications.page(params[:page]).per(25) if @applications.respond_to?(:page)

      render inertia: "App/Applications/Index", props: {
        applications: @applications.limit(100).map { |app| serialize_application(app) },
        jobs: JobPosting.ordered.map { |job| { id: job.id, title: job.title } },
        canonicalStages: canonical_stage_options,
        insightOptions: insight_filter_options,
        filters: {
          jobId: params[:job_id],
          canonicalStage: params[:canonical_stage],
          query: params[:q],
          insights: Array(params[:insights])
        }
      }
    end

    def show
      # Only show stages for this application's job
      job_stages = PipelineStage.where(job_posting_id: @application.job_posting_id).ordered
      
      render inertia: "App/Applications/Show", props: {
        application: serialize_application_full(@application),
        stages: job_stages.map { |stage| serialize_stage(stage) },
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

    def toggle_stage_completion
      stage = PipelineStage.find(params[:stage_id])
      completed = @application.toggle_stage_completion!(stage.id)

      respond_to do |format|
        format.html { redirect_to app_application_path(@application) }
        format.json { render json: { completed: completed, stageId: stage.id } }
      end
    end

    def re_evaluate
      # Get all application answers
      answers = @application.application_answers.includes(:global_question).ordered
      
      if answers.empty?
        redirect_to app_application_path(@application), alert: "No answers to evaluate"
        return
      end

      # Format all answers for evaluation
      answers_text = answers.map do |answer|
        next if answer.value.blank?
        "**#{answer.question_label}**\n#{answer.value}"
      end.compact.join("\n\n")

      if answers_text.blank?
        redirect_to app_application_path(@application), alert: "No answers to evaluate"
        return
      end

      # Evaluate using AI
      # Model selection: gpt-5.2 for recent (< 3 months), gpt-5-mini for older
      result = CoverLetterEvaluator.new(answers_text, application_date: @application.created_at).evaluate

      if result
        @application.update!(
          cover_letter_evaluation: result,
          cover_letter_decision: result[:decision]
        )
        redirect_to app_application_path(@application), notice: "AI evaluation completed"
      else
        redirect_to app_application_path(@application), alert: "AI evaluation failed"
      end
    rescue StandardError => e
      Rails.logger.error("Re-evaluation failed for app #{@application.id}: #{e.message}")
      redirect_to app_application_path(@application), alert: "AI evaluation failed: #{e.message}"
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
        countryFlag: CountryHelper.flag_from_title(app.job_posting.title),
        university: app.education&.dig("university", "name"),
        hasStartupExperience: app.has_startup_experience,
        hasYearTenure: app.has_year_tenure,
        hasPersonalProjects: app.has_personal_projects,
        coverLetterDecision: app.cover_letter_decision,
        createdAt: app.created_at.iso8601
      }
    end

    def serialize_application_full(app)
      serialize_application(app).merge(
        utmSource: app.utm_source,
        utmMedium: app.utm_medium,
        utmCampaign: app.utm_campaign,
        cvUrl: app.cv.attached? ? rails_blob_path(app.cv) : nil,
        education: app.education,
        workExperience: app.work_experience,
        hasStartupExperience: app.has_startup_experience,
        hasYearTenure: app.has_year_tenure,
        hasPersonalProjects: app.has_personal_projects,
        coverLetterDecision: app.cover_letter_decision,
        coverLetterEvaluation: app.cover_letter_evaluation,
        processingCompleted: app.processing_completed_at.present?,
        completedStageIds: app.completed_stage_ids,
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

    def canonical_stage_options
      # Get canonical stages that actually have applications, with counts
      counts = Application.joins(:current_stage)
                          .group("pipeline_stages.canonical_stage")
                          .count

      PipelineStage::CANONICAL_STAGES.map do |stage|
        {
          value: stage,
          label: stage.titleize,
          count: counts[stage] || 0
        }
      end.select { |s| s[:count] > 0 }
    end

    def filter_by_insights(scope, insights)
      insights = Array(insights)
      return scope if insights.empty?

      # Build conditions for each selected insight (OR logic between insights)
      conditions = []
      
      insights.each do |insight|
        case insight
        when "startup"
          conditions << "has_startup_experience = true"
        when "tenure"
          conditions << "has_year_tenure = true"
        when "projects"
          conditions << "has_personal_projects = true"
        when "cl_advance"
          conditions << "cover_letter_decision = 'advance'"
        when "cl_reject"
          conditions << "cover_letter_decision = 'reject'"
        end
      end

      return scope if conditions.empty?
      
      # Use OR to match any of the selected insights
      scope.where(conditions.join(" OR "))
    end

    def insight_filter_options
      [
        { value: "startup", label: "🚀 Top Startup", count: Application.where(has_startup_experience: true).count },
        { value: "tenure", label: "⏱️ +2 Years Tenure", count: Application.where(has_year_tenure: true).count },
        { value: "projects", label: "💡 Personal Projects", count: Application.where(has_personal_projects: true).count },
        { value: "cl_advance", label: "✅ Cover Letter: Advance", count: Application.where(cover_letter_decision: "advance").count },
        { value: "cl_reject", label: "❌ Cover Letter: Reject", count: Application.where(cover_letter_decision: "reject").count }
      ]
    end
  end
end
