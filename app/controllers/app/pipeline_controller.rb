module App
  class PipelineController < BaseController
    def index
      @stages = PipelineStage.ordered.includes(applications: [:candidate, :job_posting])
      @job_filter = params[:job_id].presence

      render inertia: "App/Pipeline/Index", props: {
        stages: @stages.map { |stage| serialize_stage_with_applications(stage, @job_filter) },
        jobs: JobPosting.where.not(teamtailor_id: nil).ordered.map { |job| { id: job.id, title: job.title } },
        selectedJobId: @job_filter
      }
    end

    private

    def serialize_stage_with_applications(stage, job_filter = nil)
      applications = stage.applications
      applications = applications.where(job_posting_id: job_filter) if job_filter.present?
      
      {
        id: stage.id,
        name: stage.name,
        kind: stage.kind,
        position: stage.position,
        applicationCount: applications.size,
        applications: applications.recent.limit(100).map { |app| serialize_application(app) }
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
        job: {
          id: app.job_posting.id,
          title: app.job_posting.title
        },
        createdAt: app.created_at.iso8601
      }
    end
  end
end
