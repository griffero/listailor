module App
  class ReportsController < BaseController
    def index
      render inertia: "App/Reports/Index", props: {
        candidatesPerStagePerWeek: candidates_per_stage_per_week,
        averageTimeInStage: average_time_in_stage
      }
    end

    def candidates_per_stage
      render json: candidates_per_stage_per_week
    end

    def time_in_stage
      render json: average_time_in_stage
    end

    private

    def candidates_per_stage_per_week
      # Get data for last 12 weeks
      weeks = (0..11).map { |i| i.weeks.ago.beginning_of_week.to_date }
      stages = PipelineStage.ordered

      result = weeks.map do |week_start|
        week_end = week_start + 7.days

        stage_counts = stages.map do |stage|
          count = ApplicationStageTransition
            .where(to_stage: stage)
            .where(transitioned_at: week_start..week_end)
            .count

          { stageId: stage.id, stageName: stage.name, count: count }
        end

        {
          week: week_start.strftime("%Y-%m-%d"),
          weekLabel: week_start.strftime("%b %d"),
          stages: stage_counts
        }
      end

      result.reverse
    end

    def average_time_in_stage
      stages = PipelineStage.ordered

      stages.map do |stage|
        # Find all transitions INTO this stage
        transitions = ApplicationStageTransition.where(to_stage: stage).includes(:application)

        durations = transitions.map do |transition|
          # Find the next transition from this stage
          next_transition = transition.application.stage_transitions
            .where("transitioned_at > ?", transition.transitioned_at)
            .order(transitioned_at: :asc)
            .first

          if next_transition
            (next_transition.transitioned_at - transition.transitioned_at).to_i
          else
            # Still in this stage
            (Time.current - transition.transitioned_at).to_i
          end
        end

        avg_seconds = durations.any? ? durations.sum / durations.size : 0
        avg_hours = avg_seconds / 3600.0
        avg_days = avg_hours / 24.0

        {
          stageId: stage.id,
          stageName: stage.name,
          kind: stage.kind,
          averageSeconds: avg_seconds,
          averageHours: avg_hours.round(1),
          averageDays: avg_days.round(1),
          sampleSize: durations.size
        }
      end
    end
  end
end
