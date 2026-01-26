module App
  class PipelineController < BaseController
    def index
      @job_filter = params[:job_id].presence
      
      # Auto-select first job with applications if no filter
      if @job_filter.blank?
        default_job = JobPosting.where.not(teamtailor_id: nil)
                                .joins(:applications)
                                .group("job_postings.id")
                                .order("COUNT(applications.id) DESC")
                                .first
        @job_filter = default_job&.id&.to_s
      end
      
      if @job_filter.present?
        @stages = PipelineStage.where(job_posting_id: @job_filter)
                               .ordered
                               .includes(applications: [:candidate, :job_posting])
      else
        @stages = []
      end

      render inertia: "App/Pipeline/Index", props: {
        stages: @stages.map { |stage| serialize_stage_with_applications(stage, @job_filter) },
        jobs: JobPosting.where.not(teamtailor_id: nil).ordered.map { |job| { 
          id: job.id, 
          title: job.title,
          department: job.department,
          location: job.location,
          applicationCount: job.applications.count
        } },
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
