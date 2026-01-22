module Embed
  class JobsController < BaseController
    before_action :set_job, only: [:show, :apply, :create_application]

    def index
      @jobs = JobPosting.published.ordered
    end

    def show
    end

    def apply
      @application = Application.new
      @global_questions = GlobalQuestion.ordered
      @questions = @job.job_questions.ordered
    end

    def create_application
      @global_questions = GlobalQuestion.ordered
      @questions = @job.job_questions.ordered

      # Find or create candidate (dedup by email)
      candidate = Candidate.find_or_create_by_email(
        email: application_params[:email],
        first_name: application_params[:first_name],
        last_name: application_params[:last_name],
        phone: application_params[:phone],
        linkedin_url: application_params[:linkedin_url]
      )

      # Check if candidate already applied to this job
      existing_application = Application.find_by(job_posting: @job, candidate: candidate)
      if existing_application
        flash[:alert] = "Ya has postulado a este cargo"
        redirect_to embed_job_apply_path(@job.slug)
        return
      end

      @application = Application.new(
        job_posting: @job,
        candidate: candidate,
        source: application_params[:source],
        utm_source: application_params[:utm_source],
        utm_medium: application_params[:utm_medium],
        utm_campaign: application_params[:utm_campaign],
        utm_term: application_params[:utm_term],
        utm_content: application_params[:utm_content]
      )

      # Attach CV
      if application_params[:cv].present?
        @application.cv.attach(application_params[:cv])
      end

      # Build answers for job questions
      if application_params[:answers].present?
        application_params[:answers].each do |question_id, value|
          @application.application_answers.build(
            job_question_id: question_id,
            value: value
          )
        end
      end

      # Build answers for global questions
      if application_params[:global_answers].present?
        application_params[:global_answers].each do |question_id, value|
          @application.application_answers.build(
            global_question_id: question_id,
            value: value
          )
        end
      end

      if @application.save
        redirect_to embed_job_apply_success_path(@job.slug)
      else
        flash.now[:alert] = @application.errors.full_messages.join(", ")
        render :apply, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = e.message
      @application ||= Application.new
      render :apply, status: :unprocessable_entity
    end

    def apply_success
      @job = JobPosting.published.find_by!(slug: params[:slug])
    end

    private

    def set_job
      @job = JobPosting.published.find_by!(slug: params[:slug])
    end

    def application_params
      params.require(:application).permit(
        :first_name, :last_name, :email, :phone, :linkedin_url,
        :source, :utm_source, :utm_medium, :utm_campaign, :utm_term, :utm_content,
        :cv,
        answers: {},
        global_answers: {}
      )
    end
  end
end
