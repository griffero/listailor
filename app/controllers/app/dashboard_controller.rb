module App
  class DashboardController < BaseController
    def index
      @recent_applications = Application.includes(:candidate, :job_posting, :current_stage)
                                         .recent
                                         .limit(10)
      @stages = PipelineStage.ordered
      @applications_by_stage = Application.group(:current_stage_id).count

      render inertia: "App/Dashboard", props: {
        recentApplications: @recent_applications.map { |app| serialize_application(app) },
        stages: @stages.map { |stage| serialize_stage(stage) },
        applicationsByStage: @applications_by_stage,
        stats: {
          totalApplications: Application.count,
          totalJobs: JobPosting.published.count,
          thisWeekApplications: Application.where("created_at >= ?", 1.week.ago).count
        }
      }
    end

    private

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
        stage: app.current_stage ? { id: app.current_stage.id, name: app.current_stage.name, kind: app.current_stage.kind } : nil,
        createdAt: app.created_at.iso8601
      }
    end

    def serialize_stage(stage)
      {
        id: stage.id,
        name: stage.name,
        kind: stage.kind,
        position: stage.position
      }
    end
  end
end
