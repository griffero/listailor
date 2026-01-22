module App
  class PipelineController < BaseController
    def index
      @stages = PipelineStage.ordered.includes(applications: [:candidate, :job_posting])

      render inertia: "App/Pipeline/Index", props: {
        stages: @stages.map { |stage| serialize_stage_with_applications(stage) },
        jobs: JobPosting.published.ordered.map { |job| { id: job.id, title: job.title } }
      }
    end

    private

    def serialize_stage_with_applications(stage)
      {
        id: stage.id,
        name: stage.name,
        kind: stage.kind,
        position: stage.position,
        applicationCount: stage.applications.size,
        applications: stage.applications.recent.limit(100).map { |app| serialize_application(app) }
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
