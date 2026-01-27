# frozen_string_literal: true

module App
  class ReportsController < BaseController
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
      render inertia: "App/Reports/Index", props: {
        funnelMetrics: funnel_metrics,
        hiringVelocity: hiring_velocity,
        sourceBreakdown: source_breakdown,
        timeToHire: time_to_hire_metrics,
        weeklyActivity: weekly_activity
      }
    end

    private

    def funnel_metrics
      total = Application.count
      return [] if total.zero?

      CANONICAL_STAGES.map do |canonical|
        count = Application.joins(:current_stage)
                          .where(pipeline_stages: { canonical_stage: canonical })
                          .count

        {
          stage: canonical,
          label: CANONICAL_LABELS[canonical],
          count: count,
          percentage: ((count.to_f / total) * 100).round(1),
          kind: canonical_kind(canonical)
        }
      end
    end

    def hiring_velocity
      # Hires per month for last 6 months
      (0..5).map do |months_ago|
        start_date = months_ago.months.ago.beginning_of_month
        end_date = months_ago.months.ago.end_of_month

        hired_count = Application.joins(:current_stage)
                                 .where(pipeline_stages: { canonical_stage: "hired" })
                                 .where(updated_at: start_date..end_date)
                                 .count

        applications_count = Application.where(created_at: start_date..end_date).count

        {
          month: start_date.strftime("%b %Y"),
          monthShort: start_date.strftime("%b"),
          hired: hired_count,
          applications: applications_count,
          conversionRate: applications_count > 0 ? ((hired_count.to_f / applications_count) * 100).round(1) : 0
        }
      end.reverse
    end

    def source_breakdown
      Application.group(:source).count.map do |source, count|
        {
          source: source || "Direct",
          count: count,
          percentage: ((count.to_f / Application.count) * 100).round(1)
        }
      end.sort_by { |s| -s[:count] }.first(10)
    end

    def time_to_hire_metrics
      # Average days from application to hire for hired candidates
      hired_apps = Application.joins(:current_stage)
                              .where(pipeline_stages: { canonical_stage: "hired" })
                              .where("applications.updated_at > applications.created_at")

      return { average: 0, median: 0, count: 0 } if hired_apps.empty?

      days_to_hire = hired_apps.map do |app|
        ((app.updated_at - app.created_at) / 1.day).round
      end

      sorted = days_to_hire.sort
      median = sorted[sorted.length / 2]

      {
        average: (days_to_hire.sum.to_f / days_to_hire.size).round(1),
        median: median,
        fastest: sorted.first,
        slowest: sorted.last,
        count: hired_apps.count
      }
    end

    def weekly_activity
      # Applications and hires per week for last 8 weeks
      (0..7).map do |weeks_ago|
        start_date = weeks_ago.weeks.ago.beginning_of_week
        end_date = weeks_ago.weeks.ago.end_of_week

        applications = Application.where(created_at: start_date..end_date).count

        # Stage transitions to hired this week
        hired = ApplicationStageTransition
                .joins(:to_stage)
                .where(pipeline_stages: { canonical_stage: "hired" })
                .where(transitioned_at: start_date..end_date)
                .count

        rejected = ApplicationStageTransition
                   .joins(:to_stage)
                   .where(pipeline_stages: { canonical_stage: "rejected" })
                   .where(transitioned_at: start_date..end_date)
                   .count

        {
          week: start_date.strftime("%b %d"),
          applications: applications,
          hired: hired,
          rejected: rejected
        }
      end.reverse
    end

    def canonical_kind(canonical)
      case canonical
      when "hired" then "hired"
      when "rejected" then "rejected"
      else "active"
      end
    end
  end
end
