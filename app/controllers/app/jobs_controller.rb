module App
  class JobsController < BaseController
    before_action :set_job, only: [:show, :edit, :update, :destroy, :publish, :unpublish, :archive, :unarchive]

    def index
      @jobs = JobPosting.active.ordered

      render inertia: "App/Jobs/Index", props: {
        jobs: @jobs.map { |job| serialize_job(job) }
      }
    end

    def show
      render inertia: "App/Jobs/Show", props: {
        job: serialize_job_full(@job),
        questions: @job.job_questions.ordered.map { |q| serialize_question(q) },
        applications: @job.applications.includes(:candidate, :current_stage).recent.limit(20).map { |app| serialize_application(app) }
      }
    end

    def new
      render inertia: "App/Jobs/Form", props: {
        job: nil,
        departments: Setting.departments,
        locations: Setting.locations
      }
    end

    def create
      @job = JobPosting.new(job_params)

      if @job.save
        redirect_to app_job_path(@job), notice: "Job posting created successfully"
      else
        redirect_to new_app_job_path, inertia: { errors: @job.errors.to_hash }
      end
    end

    def edit
      render inertia: "App/Jobs/Form", props: {
        job: serialize_job_full(@job),
        questions: @job.job_questions.ordered.map { |q| serialize_question(q) },
        departments: Setting.departments,
        locations: Setting.locations
      }
    end

    def update
      if @job.update(job_params)
        redirect_to app_job_path(@job), notice: "Job posting updated successfully"
      else
        redirect_to edit_app_job_path(@job), inertia: { errors: @job.errors.to_hash }
      end
    end

    def destroy
      if @job.applications.any?
        redirect_to app_jobs_path, alert: "Cannot delete job with existing applications"
      else
        @job.destroy
        redirect_to app_jobs_path, notice: "Job posting deleted"
      end
    end

    def publish
      @job.publish!
      redirect_to app_job_path(@job), notice: "Job published"
    end

    def unpublish
      @job.unpublish!
      redirect_to app_job_path(@job), notice: "Job unpublished"
    end

    def archive
      @job.archive!
      redirect_to app_jobs_path, notice: "Job archived"
    end

    def unarchive
      @job.unarchive!
      redirect_to app_job_path(@job), notice: "Job unarchived"
    end

    private

    def set_job
      @job = JobPosting.find(params[:id])
    end

    def job_params
      params.require(:job_posting).permit(:title, :description, :department, :location, :slug)
    end

    def serialize_job(job)
      {
        id: job.id,
        title: job.title,
        slug: job.slug,
        department: job.department,
        location: job.location,
        published: job.published?,
        publishedAt: job.published_at&.iso8601,
        archived: job.archived?,
        archivedAt: job.archived_at&.iso8601,
        applicationsCount: job.applications.count,
        createdAt: job.created_at.iso8601
      }
    end

    def serialize_job_full(job)
      serialize_job(job).merge(
        description: job.description
      )
    end

    def serialize_question(question)
      {
        id: question.id,
        label: question.label,
        kind: question.kind,
        required: question.required?,
        position: question.position,
        options: question.options
      }
    end

    def serialize_application(app)
      {
        id: app.id,
        candidate: {
          id: app.candidate.id,
          name: app.candidate.full_name,
          email: app.candidate.email
        },
        stage: app.current_stage ? { id: app.current_stage.id, name: app.current_stage.name, kind: app.current_stage.kind } : nil,
        createdAt: app.created_at.iso8601
      }
    end
  end
end
