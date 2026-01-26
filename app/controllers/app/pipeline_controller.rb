module App
  class PipelineController < BaseController
    # Canonical stages in display order
    CANONICAL_STAGE_ORDER = %w[inbox reviewing interview technical cultural references offer hired rejected].freeze
    CANONICAL_STAGE_LABELS = {
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
      
      canonical_stages = []
      stage_mapping = {}

      if @job_filter.present?
        # Get all applications for this job with their stages
        applications = Application.where(job_posting_id: @job_filter)
                                  .includes(:candidate, :job_posting, :current_stage)
                                  .recent

        # Get all stages for this job (for drag&drop target mapping)
        job_stages = PipelineStage.where(job_posting_id: @job_filter).ordered
        
        # Build stage mapping: canonical -> first real stage for this job
        job_stages.each do |stage|
          canonical = stage.canonical_stage || stage.infer_canonical_stage
          stage_mapping[canonical] ||= { id: stage.id, name: stage.name }
        end

        # Group applications by canonical stage
        apps_by_canonical = applications.group_by { |app| 
          app.current_stage&.canonical_stage || "inbox"
        }

        # Build canonical stages array
        canonical_stages = CANONICAL_STAGE_ORDER.map do |canonical|
          apps = apps_by_canonical[canonical] || []
          {
            canonical: canonical,
            name: CANONICAL_STAGE_LABELS[canonical],
            kind: canonical_kind(canonical),
            applicationCount: apps.size,
            applications: apps.first(100).map { |app| serialize_application(app) },
            targetStageId: stage_mapping.dig(canonical, :id)
          }
        end

        # Only show stages that have applications or are key stages
        canonical_stages = canonical_stages.select do |stage|
          stage[:applicationCount] > 0 || %w[inbox reviewing hired rejected].include?(stage[:canonical])
        end
      end

      render inertia: "App/Pipeline/Index", props: {
        stages: canonical_stages,
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
        stageName: app.current_stage&.name,
        stageId: app.current_stage&.id,
        createdAt: app.created_at.iso8601
      }
    end
  end
end
