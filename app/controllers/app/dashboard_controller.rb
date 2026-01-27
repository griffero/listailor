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
        },
        syncStats: build_sync_stats
      }
    end

    def build_sync_stats
      total = Application.count
      return empty_sync_stats if total.zero?

      from_teamtailor = Application.where.not(teamtailor_id: nil).count
      with_cv = Application.joins(:cv_attachment).count
      with_education = Application.where.not(education: nil).count
      with_work_experience = Application.where("work_experience IS NOT NULL AND jsonb_array_length(work_experience) > 0").count
      with_custom_questions = Application.where.not(teamtailor_full_sync_at: nil).count
      processing_completed = Application.where.not(processing_completed_at: nil).count

      {
        total: total,
        fromTeamtailor: from_teamtailor,
        fromTeamtailorPct: percentage(from_teamtailor, total),
        withCv: with_cv,
        withCvPct: percentage(with_cv, total),
        withEducation: with_education,
        withEducationPct: percentage(with_education, total),
        withWorkExperience: with_work_experience,
        withWorkExperiencePct: percentage(with_work_experience, total),
        withCustomQuestions: with_custom_questions,
        withCustomQuestionsPct: percentage(with_custom_questions, total),
        processingCompleted: processing_completed,
        processingCompletedPct: percentage(processing_completed, total),
        pendingExtraction: with_cv - processing_completed,
        pendingSync: from_teamtailor - with_custom_questions
      }
    end

    def empty_sync_stats
      {
        total: 0, fromTeamtailor: 0, fromTeamtailorPct: 0,
        withCv: 0, withCvPct: 0, withEducation: 0, withEducationPct: 0,
        withWorkExperience: 0, withWorkExperiencePct: 0,
        withCustomQuestions: 0, withCustomQuestionsPct: 0,
        processingCompleted: 0, processingCompletedPct: 0,
        pendingExtraction: 0, pendingSync: 0
      }
    end

    def percentage(count, total)
      return 0 if total.zero?
      ((count.to_f / total) * 100).round(1)
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
        hasStartupExperience: app.has_startup_experience,
        hasYearTenure: app.has_year_tenure,
        hasPersonalProjects: app.has_personal_projects,
        createdAt: app.created_at.iso8601
      }
    end
  end
end
