module App
  class DashboardController < BaseController
    # Canonical stages in display order
    CANONICAL_STAGES = %w[inbox reviewing interview technical cultural references offer hired rejected].freeze
    CANONICAL_LABELS = {
      "inbox" => "Inbox",
      "reviewing" => "Reviewing",
      "interview" => "Interview",
      "technical" => "Technical",
      "cultural" => "Cultural",
      "references" => "References",
      "offer" => "Offer",
      "hired" => "Hired",
      "rejected" => "Rejected"
    }.freeze

    def index
      @recent_applications = Application.includes(:candidate, :job_posting, :current_stage)
                                         .recent
                                         .limit(10)

      # Group applications by canonical stage
      applications_by_canonical = Application
        .joins(:current_stage)
        .group("pipeline_stages.canonical_stage")
        .count

      # Build canonical stages for display
      canonical_stages = CANONICAL_STAGES.map do |canonical|
        {
          canonical: canonical,
          name: CANONICAL_LABELS[canonical],
          kind: canonical_kind(canonical),
          count: applications_by_canonical[canonical] || 0
        }
      end

      render inertia: "App/Dashboard", props: {
        recentApplications: @recent_applications.map { |app| serialize_application(app) },
        canonicalStages: canonical_stages,
        stats: {
          totalApplications: Application.count,
          totalJobs: JobPosting.published.count,
          thisWeekApplications: Application.where("created_at >= ?", 1.week.ago).count
        }
      }
    end

    private

    def canonical_kind(canonical)
      case canonical
      when "hired" then "hired"
      when "rejected" then "rejected"
      else "active"
      end
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
        stage: app.current_stage ? {
          id: app.current_stage.id,
          name: app.current_stage.name,
          kind: app.current_stage.kind,
          canonical: app.current_stage.canonical_stage
        } : nil,
        createdAt: app.created_at.iso8601
      }
    end
  end
end
